#!winpty python.exe

# TODO class docstring
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
    if date is None:
        return datetime.combine(tdate.today(), datetime.min.time())
    return datetime.fromisoformat(date)


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
            date: the day; in format YYYY-MM-DD
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
            date: the day; in format YYYY-MM-DD
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
