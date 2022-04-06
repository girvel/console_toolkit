#!winpty python.exe

# TODO class docstring
# TODO partial dates

from datetime import datetime, timedelta
from datetime import date as tdate

from fire import Fire
from pymongo import MongoClient


collection = MongoClient("mongodb://localhost")['narrative']['arc_measurments']

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
    def add(self, *arcs, date=None):
        """Concatenate arcs occurences for a particular date and push results
        to database

        Args:
            arcs: arcs that occured that day
            date: for which date to append measurments; in format YYYY-MM-DD
        """
        date = parse_date(date)

        collection.update_by_date(date, {
            '$set': {
                'time': date,
            },
            '$addToSet': {
                'measurments': {'$each': arcs},
            }
        })

    def remove(self, *arcs, date=None):
        date = parse_date(date)

        collection.update_by_date(date, {
            '$pull': {
                'measurments': {'$in': arcs}
            }
        })


setattr(Cli, '+=', Cli.add)
setattr(Cli, '-=', Cli.remove)


if __name__ == '__main__':
    Fire(Cli)
