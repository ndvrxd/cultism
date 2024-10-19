class_name WeaponInfo extends Resource

## The in-game name for this weapon.
@export var wep_name:String;

## The in-game description for this weapon.
@export_multiline var wep_desc:String;

## Tbe appearance for this weapon in the inventory.
@export var inventory_sprite:Texture2D;
## @experimental
## Field for the weapon's sprite as it should appear on the character.
## This is some WAY down-the-line stuff, for once we have animations
## and a system for visually representing weapons on characters.
@export var world_sprite:Texture2D;

## The "family" this Weapon belongs to, for proficiency bonuses
@export_enum("Swords", "Knives", "Pistols", "Thrown Blades", "Unarmed", \
"Explosives", "Magic", "Boomerangs", "Hammers", "Axes", "Instruments") var category:String;

## A coefficient for how much damage this Weapon should do.
@export var damage_coefficient:float = 1

## The resource path to the primary [Ability] scene this Weapon should have.
@export_file var primaryResPath:String;

## The resource path to the secondary [Ability] scene this weapon should have.
@export_file var secondaryResPath:String;
