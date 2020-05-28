/***************************************************************************
 *
 * MobileGnuplotViewer(Quick) - a simple frontend for gnuplot
 *
 * Copyright (C) 2020 by Michael Neuroth
 *
 * License: GPL
 *
 ***************************************************************************/

#ifndef GNUPLOTINVOKER_H
#define GNUPLOTINVOKER_H

#include <QObject>
#include <QProcess>

class GnuplotInvoker : public QObject
{
    Q_OBJECT
public:
    GnuplotInvoker();

    Q_INVOKABLE QString run(const QString & sCmd);

signals:
    void sigResultReady(const QString & svgData);

public slots:
    void sltRunGnuplot();

    void sltFinishedGnuplot(int exitCode, QProcess::ExitStatus exitStatus);
    void sltErrorGnuplot(QProcess::ProcessError error);
    void sltErrorText(const QString & sTxt);

private:
    void handleGnuplotError(int exitCode);
    void runGnuplot(const QString & sScript);

    QString   m_aLastGnuplotResult;
    QString   m_aLastGnuplotError;
    QProcess  m_aGnuplotProcess;
};

#endif // GNUPLOTINVOKER_H
