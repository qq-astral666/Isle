#include "FocusTimer.h"
#include "ShelfModel.h"

#include <QFile>
#include <QSettings>
#include <QSignalSpy>
#include <QTemporaryDir>
#include <QtTest>

class TestCore : public QObject {
    Q_OBJECT

private slots:
    void initTestCase()
    {
        QCoreApplication::setOrganizationName(QStringLiteral("IsleTests"));
        QCoreApplication::setApplicationName(QStringLiteral("tst_core"));
    }

    void init() { QSettings().clear(); }

    // ------------------------------------------------------------ timer

    void timerFormats()
    {
        QCOMPARE(FocusTimer::format(0), QStringLiteral("0:00"));
        QCOMPARE(FocusTimer::format(65), QStringLiteral("1:05"));
        QCOMPARE(FocusTimer::format(25 * 60), QStringLiteral("25:00"));
        QCOMPARE(FocusTimer::format(3600 + 2 * 60 + 3), QStringLiteral("1:02:03"));
    }

    void timerStartsAndFinishes()
    {
        FocusTimer t;
        QSignalSpy finished(&t, &FocusTimer::finished);
        QVERIFY(!t.active());
        t.start(1);
        QVERIFY(t.running());
        QVERIFY(t.active());
        QCOMPARE(t.remaining(), 1);
        QTRY_COMPARE_WITH_TIMEOUT(finished.count(), 1, 3000);
        QVERIFY(!t.running());
        QVERIFY(!t.active());
        QCOMPARE(t.lastMinutes(), 0);
    }

    void timerPauseKeepsRemaining()
    {
        FocusTimer t;
        t.start(60);
        QTest::qWait(300);
        t.pause();
        const qint64 frozen = t.remainingMs();
        QVERIFY(frozen < 60000 && frozen > 59000);
        QTest::qWait(300);
        QCOMPARE(t.remainingMs(), frozen);
        QVERIFY(t.active());
        t.resume();
        QVERIFY(t.running());
    }

    void timerAddMinutesAndReset()
    {
        FocusTimer t;
        t.startMinutes(5);
        t.addMinutes(5);
        QVERIFY(t.remaining() > 9 * 60);
        QCOMPARE(t.duration(), 10 * 60);
        t.reset();
        QVERIFY(!t.active());
        QCOMPARE(t.remaining(), 0);
        t.toggle();                       // restarts with the last duration
        QVERIFY(t.running());
        QCOMPARE(t.duration(), 5 * 60);
    }

    // ------------------------------------------------------------ shelf

    void shelfAddsDedupesAndPersists()
    {
        QTemporaryDir dir;
        const QString a = dir.filePath(QStringLiteral("a.txt"));
        const QString b = dir.filePath(QStringLiteral("b.txt"));
        for (const QString& p : { a, b }) {
            QFile f(p);
            QVERIFY(f.open(QIODevice::WriteOnly));
            f.write("hello");
        }

        {
            ShelfModel shelf(QStringLiteral("shelf/test"));
            QCOMPARE(shelf.addUrls({ QUrl::fromLocalFile(a), QUrl::fromLocalFile(b) }), 2);
            QCOMPARE(shelf.count(), 2);
            QCOMPARE(shelf.addUrls({ QUrl::fromLocalFile(b) }), 0);   // duplicate
            QCOMPARE(shelf.paths().first(), b);                       // moved to front
            QCOMPARE(shelf.addUrls({ QUrl(QStringLiteral("https://example.com")) }), 0);
        }

        ShelfModel restored(QStringLiteral("shelf/test"));
        QCOMPARE(restored.count(), 2);
        QCOMPARE(restored.data(restored.index(0), ShelfModel::NameRole).toString(), QStringLiteral("b.txt"));
        QCOMPARE(restored.data(restored.index(0), ShelfModel::SizeTextRole).toString(), QStringLiteral("5 Б"));

        restored.remove(0);
        QCOMPARE(restored.count(), 1);
        restored.clear();
        QCOMPARE(restored.count(), 0);
    }

    void shelfDropsMissingFilesOnLoad()
    {
        QSettings().setValue(QStringLiteral("shelf/test"),
                             QStringList { QStringLiteral("/definitely/not/here.txt") });
        ShelfModel shelf(QStringLiteral("shelf/test"));
        QCOMPARE(shelf.count(), 0);
    }

    void iconKeyIsStable()
    {
        QCOMPARE(ShelfModel::iconKey(QStringLiteral("/tmp/x")), ShelfModel::iconKey(QStringLiteral("/tmp/x")));
        QVERIFY(ShelfModel::iconKey(QStringLiteral("/tmp/x")) != ShelfModel::iconKey(QStringLiteral("/tmp/y")));
    }
};

QTEST_GUILESS_MAIN(TestCore)
#include "tst_core.moc"
