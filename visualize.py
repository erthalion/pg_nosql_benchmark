#!/usr/bin/env python
import sys
import json
import matplotlib.pyplot as plt


COLORS = {
    "PG": 'r',
    "PGJPO": 'g',
    "PGJSQUERY": 'b',
    "MYSQL": 'k',
    "MONGO": 'y',
    "MONGONOWT": 'c',
}

LABELS = {
    "PG": 'PG 9.5b1',
    "PGJPO": 'PG 9.5b1 jpo',
    "PGJSQUERY": 'PG 9.5b1 jsquery',
    "MYSQL": 'Mysql 5.7.8',
    "MONGO": 'Mongodb 3.2.0',
    "MONGONOWT": 'Mongodb 3.2.0 MMAPv1',
}

LEGEND_ANCHOR = (1.0, 1.0)


def main(data, data_type):
    data.pop("number_of_rows")
    width = 0.25
    ax = plt.subplot(111)
    bars = []

    for test, dataset in data.iteritems():
        bars.append(
            ax.bar(
                len(bars) * (width + 0.1),
                dataset[data_type],
                width,
                color=COLORS[test]
            )
        )

    ax.set_title(LABELS[test])
    ax.margins(0.15, 0.2)
    plt.setp(ax, xticks=[],
             yticks=[0] + [d[data_type] for d in data.itervalues()])

    ax.legend(
        (bars),
        (LABELS[k] for k in data.iterkeys()),
        bbox_to_anchor=LEGEND_ANCHOR,
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
