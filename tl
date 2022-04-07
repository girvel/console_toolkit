#!python

from datetime import datetime, timedelta
from datetime import date as tdate

from termcolor import cprint, colored

from flame import flame

from fire import Fire
from pymongo import MongoClient
from colorama import init
init()


collection = MongoClient("mongodb://localhost")['narrative']['timeline']

collection.update_by_date = lambda date, update: collection.update_one(
    {
        'time': {
            '$gte': date,
            '$lt': date + timedelta(days=1),
        }
    },
    update,
    upsert=True,
)

def partial_date(date):
    values = [] if date is None else list(map(int, date.split('-')))[::-1]
    today = tdate.today()

    return datetime.combine(
        tdate(
            len(values) > 2 and values[2] or today.year,
            len(values) > 1 and values[1] or today.month,
            len(values) > 0 and values[0] or today.day,
        ),
        datetime.min.time()
    )


@flame
class Cli:
    """CLI for interaction with timeline DB

    Timeline is a representation of the flow of life. Each day is characterised
    by set of plot lines that manifested themselves during the day as events.

    This script allows to edit information about the timeline, adding or
    removing plot lines events for a particular day.
    """

    def add(self, *events, date: partial_date=None):
        """Add events for a particular day

        Args:
            events: plot lines that manifested themselves during this day
            date: the day
        """

        collection.update_by_date(date, {
            '$set': {
                'time': date,
            },
            '$addToSet': {
                'events': {'$each': events},
            }
        })

    def remove(self, *events, date: partial_date=None):
        """Remove events for a particular day.

        Args:
            events: plot lines that should be removed from this day
            date: the day
        """

        collection.update_by_date(date, events == ("_", )
            and {'$set': {
                'events': []
            }}
            or {'$pull': {
                'events': {'$in': events}
            }}
        )

    def show(self):
        """Displays current timeline"""

        everything = sorted(list(collection.find({})), key=lambda d: d['time'])

        plotlines = list(set(
            sum((d['events'] for d in everything), [])
        ))

        rainbow = 'red yellow green cyan blue magenta'.split()
        cell_w = 6

        print()

        for d in everything:
            day = d['time'].day

            print(' ' * (cell_w - 2), end='')
            if day < 10:
                print(f'0{day}', end='')
            else:
                print(f'{day}', end='')
        print()

        for i, line in enumerate(plotlines):
            line_color = rainbow[i % len(rainbow)]

            for i, d in enumerate(everything):
                colors = (line in d['events']
                    and ('grey', 'on_' + line_color)
                    or ('white', 'on_grey'))

                cprint(
                    ' ' * cell_w,
                    *colors,
                    end=''
                )
            print()

            i = 0
            for i, d in enumerate(everything):
                colors = (line in d['events']
                    and ('grey', 'on_' + line_color)
                    or ('white', 'on_grey'))

                for j in range(cell_w):
                    cprint(
                        line[cell_w * i + j] if len(line) > cell_w * i + j else ' ',
                        *colors,
                        end=''
                    )

            print(line[cell_w * i + 1:])


setattr(Cli, '+=', Cli.add)
setattr(Cli, '-=', Cli.remove)


if __name__ == '__main__':
    Fire(Cli)
