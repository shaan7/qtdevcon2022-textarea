#pragma once

#include <QStringListModel>

class MessagesModel : public QStringListModel
{
    Q_OBJECT

public:
    using QStringListModel::QStringListModel;
};

