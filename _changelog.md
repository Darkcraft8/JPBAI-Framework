### Json Behavior Powered Active Item : Changelog

#### Change
  - JPBAI.lua now load the movement custom functions
  - Added code segments that where missing in the stances lerp function
  - The projectile event no longer override the `power` and `powerMultiplier` parameter that are given inside of the event projectile `parameter`
  - Streamlined the `fireOffset` option for `spawnPos` in the `spawnPosition` function (used in the projectile event for exemple)
  
#### Added
  - `JPBAI.lua`
    - added uninitEvent parameter .
    <br>The item's uninitialization will cause any events in this `table` parameter to be executed.
  - `Behavior Extra`
    - setItemShieldPolys(partName, propertyName)
    <br> set the item's current shield polygons based on the given partName and propertyName
    - resetItemShieldPolys()
    <br> reset the items shield polygons
  - `Movement Module`
	- movementControl.translateAboveGround(distance)
	<br> shift the owner position upward based on the given distance (in tiles) to the ground
	- movementControl.aimVelocity(vel, verticalOffset)
	<br> Add the given **velocity** to the item user based on their **aimAngle**. a `verticalOffset`(float) can be given
	- movementControl.aimTranslation(vec, verticalOffset, checkForObstacle, offset, maxCorrection)<br>
	Add the given **vector** to the item user based on their **aimAngle**. a `verticalOffset`(float) can be given.<br>
	If checkForObstacle isn't false or nil, Then the translation distance will be reduced to prevent the traversal of obstacle.<br>
	The user position will be resolved before being applied as to **Hopefully** not cause them to be stuck
	an offset(default [0, 2.5]) and the number of maximum Correction(3 by default) can be given.
#### Fixed
  - added `nil` check for callback in JPBAI.lua so that
  <br>they don't cause problem if the given function(s) doesn't exist
  - `Status Module`
	- Fixed statusEx.hasResources(resourceList) using the old args passing method causing any resource check to pass

#### Still need to be made
  - Resources func still need to be made ?
  - Movement func still need to be made ?
  - Documentation Need to be Made !!!