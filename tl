#!winpty python.exe

# TODO partial dates
# TODO lib
# TODO `tl -= *`

from datetime import datetime, timedelta
from datetime import date as tdate

from fire import Fire
from pymongo import MongoClient


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

def parse_date(date):
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


class Cli:
    """CLI for interaction with timeline DB

    Timeline is a representation of the flow of life. Each day is characterised
    by set of plot lines that manifested themselves during the day as events.

    This script allows to edit information about the timeline, adding or
    removing plot lines events for a particular day.
    """

    def add(self, *events, date=None):
        """Add events for a particular day

        Args:
            events: plot lines that manifested themselves during this day
            date: the day; in format [[YYYY]-MM]-DD
        """
        date = parse_date(date)

        collection.update_by_date(date, {
            '$set': {
                'time': date,
            },
            '$addToSet': {
                'events': {'$each': events},
            }
        })

    def remove(self, *events, date=None):
        """Remove events for a particular day.

        Args:
            events: plot lines that should be removed from this day
            date: the day; in format [[YYYY]-MM]-DD
        """
        date = parse_date(date)

        collection.update_by_date(date, {
            '$pull': {
                'events': {'$in': events}
            }
        })


setattr(Cli, '+=', Cli.add)
setattr(Cli, '-=', Cli.remove)


if __name__ == '__main__':
    Fire(Cli)
