#pragma once

#include "FocusTimer.h"
#include "ShelfModel.h"

#include <QtQml/qqmlregistration.h>

// The core library has no QML dependency; expose its classes to QML here.
struct FocusTimerForeign {
    Q_GADGET
    QML_FOREIGN(FocusTimer)
    QML_NAMED_ELEMENT(FocusTimer)
    QML_UNCREATABLE("Owned by NotchController")
};

struct ShelfModelForeign {
    Q_GADGET
    QML_FOREIGN(ShelfModel)
    QML_NAMED_ELEMENT(ShelfModel)
    QML_UNCREATABLE("Owned by NotchController")
};
