#!/usr/bin/env python
# a bar plot with errorbars
import sys
import json
import matplotlib.pyplot as plt


COLORS = {
    "PG": '#8172b2',
    "PGJPO": '#4c72b0',
    "PGJSQUERY": '#64b5cd',
    "MYSQL": '#55a868',
    "MONGO": '#c44e52',
    "MONGONOWT": '#ccb974',
}

TITLES = {
    "select": "Select (sec)",
    "insert": "Insert (sec)",
    "update": "Update (sec)",
    "table_size": "Table/collection size (mb)",
    "index_size": "Index size (mb)",
}

LABELS = {
    "PG": 'PG 9.5b1',
    "PGJPO": 'PG 9.5b1 jpo',
    "PGJSQUERY": 'PG 9.5b1 jsquery',
    "MYSQL": 'Mysql 5.7.8',
    "MONGO": 'Mongodb 3.2.0',
    "MONGONOWT": 'Mongodb 3.2.0 MMAPv1',
}

SCALES = {
    "select": 1e9,
    "insert": 1e9,
    "update": 1e9,
    "table_size": 2**20,
    "index_size": 2**20,
}

NEED_CORRECTION = {
    "select": True,
    "insert": True,
    "update": True,
    "table_size": False,
    "index_size": False,
}

EXCLUDE_TICKS = {
    "select": ["MONGONOWT", "PG"],
    "insert": ["MONGONOWT", "PG", "PGJSQUERY"],
    "update": ["MONGO", "MONGONOWT"],
    "table_size": ["MONGO"],
    "index_size": ["PGJSQUERY"],
}

def scale_dataset(dataset):
    return {
        key: float(value) / SCALES[key]
        for key, value in dataset.iteritems()
    }

def correct_dataset(dataset):
    noop = dataset.pop("noop")
    return {
        key: value - NEED_CORRECTION[key] * noop
        for key, value in dataset.iteritems()
    }

def main(data, data_type):
    data.pop("number_of_rows")
    width = 0.25       # the width of the bars
    ax = plt.subplot(111)
    bars = []
    anchor = (1.0, 1.0)

    if data_type == "index_size":
        anchor = (0.4, 1.0)

    for key, ds in data.iteritems():
        data[key] = correct_dataset(ds)
        data[key] = scale_dataset(ds)

    for test, dataset in data.iteritems():
        bars.append(
            ax.bar(
                len(bars) * (width + 0.1),
                dataset[data_type],
                width,
                color=COLORS[test]
            )
        )


    ax.set_title(TITLES[data_type])
    ax.margins(0.15, 0.2)
    plt.setp(ax, xticks=[],
             yticks=[0] + [d
                           [data_type] for k, d in data.iteritems()
                           if k not in EXCLUDE_TICKS[data_type]
                           ])

    ax.legend(
        (bars),
        (LABELS[k] for k in data.iterkeys()),
        bbox_to_anchor=anchor,
    )

    plt.show()


def usage():
    print "Usage: visualize.py filename type"
    "filename is a json file with benchmark data"
    "type is one of ['select', 'insert', 'update', 'collection_size', 'index_size']"


if __name__ == "__main__":
    if len(sys.argv) != 3:
        usage()

    try:
        data = json.load(open(sys.argv[1]))
        data_type = sys.argv[2]
    except IOError as ex:
        print "Cannot open benchmark file. Error {}".format(ex)

    except ValueError as ex:
        print "Benchmark file isn't correct json. Error {}".format(ex)

    main(data, data_type)
