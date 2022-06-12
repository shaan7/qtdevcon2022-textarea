#include "messagesmodel.h"

#include <QFile>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>

int main(int argc, char *argv[])
{
#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
#endif
    QGuiApplication app(argc, argv);

    QQmlApplicationEngine engine;
    const QUrl url(QStringLiteral("qrc:/main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);

    QFile chatLogfile(":/chat.log");
    if (!chatLogfile.open(QIODevice::ReadOnly)) {
        qFatal("%s", chatLogfile.errorString().toUtf8().data());
        return 1;
    }

    // 1. Raw chat log
    const auto chatLog = chatLogfile.readAll();
    engine.rootContext()->setContextProperty("chatLog", chatLog);

    // 2. Model with chat log lines
    const auto chatLinesArray = chatLog.split('\n');
    QStringList chatLines;
    chatLines.reserve(chatLinesArray.size());
    for (const auto &l : chatLinesArray)
        chatLines.append(l);

    MessagesModel chatLogModel;
    chatLogModel.setStringList(chatLines);
    engine.rootContext()->setContextProperty("chatLogModel", &chatLogModel);

    engine.load(url);

    return app.exec();
}
