# Require param for possibleOutcome

* fireMode | string, default to none if nil
none, primary or alt

* stance | string stanceName
wait for the current stance to be of the same name

* function | string FuncName/Path or array {callback = FuncName/Path, args = args}
check if the given function return true or a possitif value

* isShiftHeld | Boolean
require shift to be either held or not