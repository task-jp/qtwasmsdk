#include <QtHttpServer>

QByteArray readBinaryFile(const QString &fileName) {
    QByteArray ret;
    QFile file(fileName);
    if (file.open(QFile::ReadOnly)) {
        ret = file.readAll();
        file.close();
    }
    return ret;
}

int main(int argc, char **argv)
{
    QCoreApplication app(argc, argv);
    
    QCommandLineParser parser;
    parser.addOptions({
        {
	    {"a", "application"}, 
            QCoreApplication::translate("main", "Application name, Default example"),
            QCoreApplication::translate("main", "application"),
            QCoreApplication::translate("main", "example")
	},
        {
	    {"p", "port"}, 
            QCoreApplication::translate("main", "Port. Default: 8080"),
            QCoreApplication::translate("main", "port"),
            QCoreApplication::translate("main", "8080")
	}
    });

    parser.process(app);
    const QString application = parser.value("application");
    const quint16 port = parser.value("port").toUInt();

    QString fileName = QStringLiteral("%3/%1.%2").arg(application);

    QHttpServer server;
    server.route("/", "GET", [&]() {
        return readBinaryFile(fileName.arg("html", "."));
    });
    server.route(fileName.arg("js", ""), "GET", [&]() {
        return readBinaryFile(fileName.arg("js", "."));
    });
    server.route(fileName.arg("wasm", ""), "GET", [&]() {
        return readBinaryFile(fileName.arg("wasm", "."));
    });
    server.route("/qtloader.js", "GET", [&]() {
        return readBinaryFile("qtloader.js");
    });
    server.route("/qtlogo.svg", "GET", [&]() {
        return readBinaryFile("qtlogo.svg");
    });
    server.listen(QHostAddress::Any, port);

    return app.exec();
}
