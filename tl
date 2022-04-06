#!winpty python.exe

# TODO class docstring
# TODO remove date
# TODO extract common logic
# TODO partial dates

from datetime import datetime, timedelta

from fire import Fire
from pymongo import MongoClient


class Cli:
    def concat(self, *occured_arcs, date=None):
        """Concatenate arcs occurences for a particular date and push results
        to database

        Args:
            occured_arcs: arcs that occured that day
            date: for which date to append measurments; in format YYYY-MM-DD
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


setattr(Cli, '..=', Cli.concat)


if __name__ == '__main__':
    Fire(Cli)
