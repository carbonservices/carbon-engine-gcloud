#ifndef SERVER_CONFIG_H
#define SERVER_CONFIG_H

#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QProcessEnvironment>
#include <QStandardPaths>
#include <QString>

#include "constants/CommonConstants.h"

const int kEmbeddingDim = ServerDefaults::DefaultEmbeddingDim;
const quint16 kDefaultPort = ServerDefaults::DefaultPort;

inline QString resolveModelPath(const QString &name, const QString &fallback)
{
    QString envVal = QProcessEnvironment::systemEnvironment().value(name);
    if (!envVal.isEmpty()) {
        return envVal;
    }
    // Check user Documents/CarbonESG/models folder
    QString docDir = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation) + "/CarbonESG/models";
    QString docModelPath = QDir(docDir).filePath(QFileInfo(fallback).fileName());
    if (QFile::exists(docModelPath)) {
        return docModelPath;
    }
    if (QFile::exists(fallback)) {
        return fallback;
    }
    QString appRelative = QDir(QCoreApplication::applicationDirPath()).filePath(fallback);
    if (QFile::exists(appRelative)) {
        return appRelative;
    }
    QString parentRelative = QDir(QCoreApplication::applicationDirPath() + "/../../..").filePath(fallback);
    if (QFile::exists(parentRelative)) {
        return parentRelative;
    }
    return fallback;
}

inline QString resolveDatabasePath()
{
    QString envVal = QProcessEnvironment::systemEnvironment().value("CARBON_ENGINE_DB_PATH");
    if (!envVal.isEmpty()) {
        return envVal;
    }
    QString docDir = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation) + "/CarbonESG/data";
    QDir().mkpath(docDir);
    return docDir + "/ce-database.sqlite";
}

const QString kDatabaseFilePath = resolveDatabasePath();
const QString kGenerationModelPath = resolveModelPath("CARBON_ENGINE_GEN_MODEL", Models::LocalGemmaFile);
const QString kEmbeddingModelPath = resolveModelPath("CARBON_ENGINE_EMBD_MODEL", Models::LocalBgeEmbeddingFile);

#endif // SERVER_CONFIG_H
