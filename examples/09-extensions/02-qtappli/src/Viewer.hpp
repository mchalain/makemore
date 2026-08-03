#ifndef __VIEWER_HPP__
#define __VIEWER_HPP__

#include <QAbstractTableModel>

class Viewer : public QAbstractTableModel
{
    Q_OBJECT
public:
    Viewer(QObject *parent = nullptr);
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    int columnCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
};

#endif
