#!winpty python.exe
from datetime import datetime, timedelta

from fire import Fire
from pymongo import MongoClient


def append_arc_measurments(*occured_arcs, date=None):
    """Append arcs occurences to a database

    Args:
        occured_arcs: arcs, event from which happened this day
        date: for which date to append measurments in format YYYY-MM-DD
    """
    if date is None:
        date = datetime.now()
    else:
        date = datetime.fromisoformat(date)


    collection = MongoClient("mongodb://localhost") \
        ['narrative']['arc_measurments']


    collection.update_one(
        {
            'time': {
                '$gte': date,
                '$lt': date + timedelta(days=1),
            }
        },
        {
            '$set': {
                'time': date,
            },
            '$addToSet': {
                'measurments': {'$each': occured_arcs},
            }
        },
        upsert=True,
    )


if __name__ == '__main__':
    Fire(append_arc_measurments)
