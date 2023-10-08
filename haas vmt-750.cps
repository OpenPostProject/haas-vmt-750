/**
  Copyright (C) 2012-2023 by Autodesk, Inc.
  All rights reserved.

  HAAS VMT-750 Lathe post processor configuration.

  $Revision: 44083 1c5ad993a086f043365c6f9038d5d6561bad0ddd $
  $Date: 2023-08-12 05:06:32 $

  FORKID {0B09E00E-4EEC-4979-B58C-775B20C7F915}
*/

description = "HAAS VMT-750";

var gotYAxis = true;
var xAxisMinimum = toPreciseUnit(-51, MM);
var yAxisMinimum = toPreciseUnit(gotYAxis ? -330.0 : 0, MM); // specifies the minimum range for the Y-axis
var yAxisMaximum = toPreciseUnit(gotYAxis ? 89.0 : 0, MM); // specifies the maximum range for the Y-axis
var gotBAxis = true; // B-axis always requires customization to match the machine specific functions for doing rotations
var gotMultiTurret = false; // specifies if the machine has several turrets
var gotLiveTooling = true; // specifies that the machine has a live spindle
var gotSecondarySpindle = false; // specifies that the machine has a secondary spindle
var g53HomePositionSubZ = 0; // subspindle home position
var g53WorkPositionSub = 0; // subspindle working position
var subMaximumSpindleSpeed = 0; // subspindle maximum spindle speed

var gotDoorControl = false;

///////////////////////////////////////////////////////////////////////////////
//                        MANUAL NC COMMANDS
//
// The following ACTION commands are supported by this post.
//
//     partEject                  - Manually eject the part
//     usePolarMode               - Force Polar mode for next operation
//     useXZCMode                 - Force XZC mode for next operation
//
///////////////////////////////////////////////////////////////////////////////

if (!description) {
  description = "HAAS Lathe";
}
vendor = "Haas Automation";
vendorUrl = "https://www.haascnc.com";
legal = "Copyright (C) 2012-2023 by Autodesk, Inc.";
certificationLevel = 2;
minimumRevision = 45793;

if (!longDescription) {
  longDescription = subst("Preconfigured %1 post with support for mill-turn. You can force G112 mode for a specific operation by using Manual NC Action with keyword 'usepolarmode'.", description);
}

extension = "nc";
programNameIsInteger = true;
setCodePage("ascii");
keywords = "MODEL_IMAGE PREVIEW_IMAGE";

capabilities = CAPABILITY_MILLING | CAPABILITY_TURNING | CAPABILITY_MACHINE_SIMULATION;
tolerance = spatial(0.002, MM);

minimumChordLength = spatial(0.25, MM);
minimumCircularRadius = spatial(0.01, MM);
maximumCircularRadius = spatial(1000, MM);
minimumCircularSweep = toRad(0.01);
maximumCircularSweep = toRad(120); // reduced sweep due to G112 support
allowHelicalMoves = true;
allowedCircularPlanes = undefined; // allow any circular motion
allowSpiralMoves = false;
highFeedrate = (unit == IN) ? 470 : 12000;

// user-defined properties
properties = {
  writeMachine: {
    title      : "Write machine",
    description: "Output the machine settings in the header of the code.",
    group      : "formats",
    type       : "boolean",
    value      : false,
    scope      : "post"
  },
  writeTools: {
    title      : "Write tool list",
    description: "Output a tool list in the header of the code.",
    group      : "formats",
    type       : "boolean",
    value      : false,
    scope      : "post"
  },
  writeVersion: {
    title      : "Write version",
    description: "Write the version number in the header of the code.",
    group      : "formats",
    type       : "boolean",
    value      : false,
    scope      : "post"
  },
  showSequenceNumbers: {
    title      : "Use sequence numbers",
    description: "'Yes' outputs sequence numbers on each block, 'Only on tool change' outputs sequence numbers on tool change blocks only, and 'No' disables the output of sequence numbers.",
    group      : "formats",
    type       : "enum",
    values     : [
      {title:"Yes", id:"true"},
      {title:"No", id:"false"},
      {title:"Only on tool change", id:"toolChange"}
    ],
    value: "false",
    scope: "post"
  },
  sequenceNumberStart: {
    title      : "Start sequence number",
    description: "The number at which to start the sequence numbers.",
    group      : "formats",
    type       : "integer",
    value      : 10,
    scope      : "post"
  },
  sequenceNumberIncrement: {
    title      : "Sequence number increment",
    description: "The amount by which the sequence number is incremented by in each block.",
    group      : "formats",
    type       : "integer",
    value      : 1,
    scope      : "post"
  },
  optionalStop: {
    title      : "Optional stop",
    description: "Outputs optional stop code during when necessary in the code.",
    group      : "preferences",
    type       : "boolean",
    value      : true,
    scope      : "post"
  },
  separateWordsWithSpace: {
    title      : "Separate words with space",
    description: "Adds spaces between words if 'yes' is selected.",
    group      : "formats",
    type       : "boolean",
    value      : true,
    scope      : "post"
  },
  useRadius: {
    title      : "Radius arcs",
    description: "If yes is selected, arcs are outputted using radius values rather than IJK.",
    group      : "preferences",
    type       : "boolean",
    value      : false,
    scope      : "post"
  },
  maximumSpindleSpeed: {
    title      : "Max spindle speed",
    description: "Defines the maximum spindle speed allowed on the main spindle.",
    group      : "configuration",
    type       : "integer",
    range      : [0, 999999999],
    value      : 8100,
    scope      : "post"
  },
  useParametricFeed: {
    title      : "Parametric feed",
    description: "Specifies the feed value that should be output using a Q value.",
    group      : "preferences",
    type       : "boolean",
    value      : false,
    scope      : "post"
  },
  showNotes: {
    title      : "Show notes",
    description: "Writes operation notes as comments in the output code.",
    group      : "formats",
    type       : "boolean",
    value      : false,
    scope      : "post"
  },
  useCycles: {
    title      : "Use cycles",
    description: "Specifies if canned drilling cycles should be used.",
    group      : "preferences",
    type       : "boolean",
    value      : true,
    scope      : "post"
  },
  autoEject: {
    title      : "Auto eject",
    description: "Specifies whether the part should automatically eject at the end of a program.",
    group      : "preferences",
    type       : "boolean",
    value      : false,
    scope      : "post"
  },
  safeRetractDistanceX: {
    title      : "Safe Z-retract distance for head rotations (in)",
    description: "Specifies in inches the distance above the part to retract to when positioning rotary axes on a head machine.",
    group      : "multiAxis",
    type       : "number",
    value      : 2,
    scope      : "post"
  },
  safeRetractDistanceZ: {
    title      : "Safe Z-retract distance for head rotations (in)",
    description: "Specifies in inches the distance above the part to retract to when positioning rotary axes on a head machine.",
    group      : "multiAxis",
    type       : "number",
    value      : 4,
    scope      : "post"
  },
  useMultiAxisFeatures: {
    title      : "Use FCS",
    description: "Specifies that the Feature Coordinate System (G268/G269) should be used.",
    group      : "multiAxis",
    type       : "boolean",
    value      : true,
    scope      : "post"
  },
  homePositionX: {
    title      : "G53 home position X (in)",
    description: "G53 X-axis home position in inches.",
    group      : "homePositions",
    type       : "number",
    value      : 0,
    scope      : "post"
  },
  homePositionY: {
    title      : "G53 home position Y (in)",
    description: "G53 Y-axis home position in inches.",
    group      : "homePositions",
    type       : "number",
    value      : -10,
    scope      : "post"
  },
  homePositionZ: {
    title      : "G53 home position Z (in)",
    description: "G53 Z-axis home position in inches.",
    group      : "homePositions",
    type       : "number",
    value      : 0,
    scope      : "post"
  },
  useTailStock: {
    title      : "Use tail stock",
    description: "Enable to use the tail stock.",
    group      : "configuration",
    type       : "boolean",
    value      : false,
    scope      : "post"
  },
  useBarFeeder: {
    title      : "Use bar feeder",
    description: "Enable to use the bar feeder.",
    group      : "configuration",
    type       : "boolean",
    value      : false,
    scope      : "post"
  },
  gotChipConveyor: {
    title       : "Got chip conveyor",
    description : "Specifies whether to use a chip conveyor.",
    group       : "configuration",
    type        : "boolean",
    presentation: "yesno",
    value       : false,
    scope       : "post"
  },
  useG112: {
    title      : "Use G112 polar interpolation",
    description: "If enabled, the G112 feature will be used for polar interpolation. " + EOL +
      "If disabled, the postprocessor will calculate and output XZC coordinates.",
    group: "preferences",
    type : "boolean",
    value: false,
    scope: "post"
  },
  usePolarCircular: {
    title      : "Use G2/G3 with G112 polar interpolation",
    description: "Enables circular interpolation output while using G112 polar mode.",
    group      : "preferences",
    type       : "boolean",
    value      : false,
    scope      : "post"
  },
  useG61: {
    title      : "Use G61 exact stop mode",
    description: "Enables exact stop mode.",
    group      : "preferences",
    type       : "boolean",
    value      : false,
    scope      : "post"
  },
  useSSV: {
    title      : "Use SSV",
    description: "Outputs M38/M39 to enable SSV for turning operations.",
    group      : "preferences",
    type       : "boolean",
    value      : false,
    scope      : "post"
  },
  looping: {
    title       : "Use M97 looping",
    description : "Output program for M97 looping.",
    group       : "looping",
    type        : "boolean",
    presentation: "yesno",
    value       : false,
    scope       : "post"
  },
  numberOfRepeats: {
    title      : "Number of repeats",
    description: "How many times to loop the program.",
    group      : "looping",
    type       : "integer",
    range      : [0, 99999999],
    value      : 1,
    scope      : "post"
  },
  useSimpleThread: {
    title      : "Use simple threading cycle",
    description: "Enable to output G92 simple threading cycle, disable to output G76 standard threading cycle.",
    group      : "preferences",
    type       : "boolean",
    value      : true,
    scope      : "post"
  },
  cleanAir: {
    title      : "Air clean chucks",
    description: "Enable to use the air blast to clean out the chuck on part transfers and part ejection.",
    group      : "preferences",
    type       : "boolean",
    value      : true,
    scope      : "post"
  },
  safeStartAllOperations: {
    title      : "Safe start all operations",
    description: "Write optional blocks at the beginning of all operations that include all commands to start program.",
    group      : "preferences",
    type       : "boolean",
    value      : false,
    scope      : "post"
  },
  useYAxisForDrilling: {
    title      : "Position in Y for axial drilling",
    description: "Positions in Y for axial drilling options when it can instead of using the C-axis.",
    group      : "preferences",
    type       : "boolean",
    value      : false,
    scope      : "post"
  },
  useSmoothing: {
    title      : "Use G187",
    description: "G187 smoothing mode.",
    group      : "preferences",
    type       : "enum",
    values     : [
      {title:"Off", id:"-1"},
      {title:"Automatic", id:"9999"},
      {title:"Rough", id:"1"},
      {title:"Medium", id:"2"},
      {title:"Finish", id:"3"}
    ],
    value: "-1",
    scope: "post"
  },
  radiusMode: {
    title      : "Radius/Diameter Mode",
    description: "Specify the X-axis output mode with or without the corresponding G171/G172 code.  The G171/G172 codes override setting 285 in the controller.",
    group      : "preferences",
    type       : "enum",
    values     : [
      {title:"Radius", id:"radius"},
      {title:"Diameter", id:"diameter"},
      {title:"Radius with G171", id:"g171"},
      {title:"Diameter with G172", id:"g172"},
    ],
    value: "diameter",
    scope: "post"
  },
  useM130PartImages: {
    title      : "Include M130 part images",
    description: "Enable to include M130 part images with the NC file.",
    group      : "formats",
    type       : "boolean",
    value      : false,
    scope      : "post"
  },
  useM130ToolImages: {
    title      : "Include M130 tool images",
    description: "Enable to include M130 tool images with the NC file.",
    group      : "formats",
    type       : "boolean",
    value      : false,
    scope      : "post"
  },
};

groupDefinitions = {
  looping: {title:"Looping", collapsed:true, order:25},
};

// wcs definiton
wcsDefinitions = {
  useZeroOffset: false,
  wcs          : [
    {name:"Standard", format:"G", range:[54, 59]},
    {name:"Extended", format:"G154 P", range:[1, 99]}
  ]
};

var singleLineCoolant = true; // specifies to output multiple coolant codes in one line rather than in separate lines
// samples:
// {id: COOLANT_THROUGH_TOOL, on: 88, off: 89}
// {id: COOLANT_THROUGH_TOOL, on: [8, 88], off: [9, 89]}
// {id: COOLANT_THROUGH_TOOL, turret1:{on: [8, 88], off:[9, 89]}, turret2:{on:88, off:89}}
// {id: COOLANT_THROUGH_TOOL, spindle1:{on: [8, 88], off:[9, 89]}, spindle2:{on:88, off:89}}
// {id: COOLANT_THROUGH_TOOL, spindle1t1:{on: [8, 88], off:[9, 89]}, spindle1t2:{on:88, off:89}}
// {id: COOLANT_THROUGH_TOOL, on: "M88 P3 (myComment)", off: "M89"}
var coolants = [
  {id:COOLANT_FLOOD, on:8, off:9},
  {id:COOLANT_MIST},
  {id:COOLANT_THROUGH_TOOL, on:388, off:389},
  {id:COOLANT_AIR, on:83, off:84},
  {id:COOLANT_AIR_THROUGH_TOOL},
  {id:COOLANT_SUCTION},
  {id:COOLANT_FLOOD_MIST},
  {id:COOLANT_FLOOD_THROUGH_TOOL, on:[8, 388], off:[9, 389]},
  {id:COOLANT_OFF, off:9}
];

var permittedCommentChars = " ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.,=_-";

var gFormat = createFormat({prefix:"G", decimals:0});
var mFormat = createFormat({prefix:"M", decimals:0});
var pFormat = createFormat({prefix:"P", decimals:0});

var spatialFormat = createFormat({decimals:(unit == MM ? 3 : 4), forceDecimal:true});
var xFormat; // defined in onOpen
var yFormat = createFormat({decimals:(unit == MM ? 3 : 4), forceDecimal:true});
var zFormat = createFormat({decimals:(unit == MM ? 3 : 4), forceDecimal:true});
var rFormat = createFormat({decimals:(unit == MM ? 3 : 4), forceDecimal:true}); // radius
var abcFormat = createFormat({decimals:3, forceDecimal:true, scale:DEG});
var cFormat = createFormat({decimals:3, forceDecimal:true, scale:DEG});
var feedFormat = createFormat({decimals:(unit == MM ? 3 : 4), forceDecimal:true});
var inverseTimeFormat = createFormat({decimals:3, forceDecimal:true});
var pitchFormat = createFormat({decimals:(unit == MM ? 3 : 4), forceDecimal:true});
var toolFormat = createFormat({decimals:0});
var rpmFormat = createFormat({decimals:0});
var secFormat = createFormat({decimals:3, forceDecimal:true}); // seconds - range 0.001-99999.999
var milliFormat = createFormat({decimals:0}); // milliseconds // range 1-9999
var taperFormat = createFormat({decimals:1, scale:DEG});
var integerFormat = createFormat({decimals:0, forceDecimal:false, trim:true});
var threadQFormat = createFormat({decimals:3, forceDecimal:false, trimLeadZero:true, scale:1000});
var g76AFormat = createFormat({decimals:(unit == MM ? 3 : 4)});

var xOutput; // defined in onOpen
var yOutput = createVariable({onchange:function() {retracted[Y] = false;}, prefix:"Y"}, yFormat);
var zOutput = createVariable({onchange:function() {retracted[Z] = false;}, prefix:"Z"}, zFormat);
var aOutput = createVariable({prefix:"A"}, abcFormat);
var bOutput = createVariable({prefix:"B"}, abcFormat);
var cOutput = createVariable({prefix:"C"}, cFormat);
var feedOutput = createVariable({prefix:"F"}, feedFormat);
var inverseTimeOutput = createVariable({prefix:"F", force:true}, inverseTimeFormat);
var pitchOutput = createVariable({prefix:"F", force:true}, pitchFormat);
var sOutput = createVariable({prefix:"S", force:true}, rpmFormat);
var pOutput = createVariable({prefix:"P", force:true}, rpmFormat);

// circular output
var iOutput = createReferenceVariable({prefix:"I", force:true}, spatialFormat);
var jOutput = createReferenceVariable({prefix:"J", force:true}, spatialFormat);
var kOutput = createReferenceVariable({prefix:"K", force:true}, spatialFormat);

// cycle thread output
var g76IOutput = createVariable({prefix:"I", force:true}, zFormat); // no scaling
var g76KOutput = createVariable({prefix:"K", force:true}, zFormat); // no scaling
var g76DOutput = createVariable({prefix:"D", force:true}, zFormat); // no scaling
var g76AOutput = createVariable({prefix:"A", force:true}, g76AFormat); // no scaling
var g76QOutput = createVariable({prefix:"Q", force:true}, threadQFormat);
var g92IOutput = createVariable({prefix:"I"}, zFormat); // no scaling
var g92QOutput = createVariable({prefix:"Q"}, threadQFormat);

var gMotionModal = createModal({}, gFormat); // modal group 1 // G0-G3, ...
var gPlaneModal = createModal({onchange:function () {gMotionModal.reset();}}, gFormat); // modal group 2 // G17-19
var gAbsIncModal = createModal({}, gFormat); // modal group 3 // G390-391
var gFeedModeModal = createModal({}, gFormat); // modal group 5 // G98-99
var gSpindleModeModal = createModal({}, gFormat); // modal group 5 // G96-97
var gSynchronizedSpindleModal = createModal({}, gFormat); // G198/G199
var gSpindleModal = createModal({}, gFormat); // G14/G15 SPINDLE MODE
var gUnitModal = createModal({}, gFormat); // modal group 6 // G20-21
var gCycleModal = createModal({}, gFormat); // modal group 9 // G81, ...
var gPolarModal = createModal({}, gFormat); // G112, G113
var ssvModal = createModal({}, mFormat); // M38, M39
var cAxisEngageModal = createModal({}, mFormat);
var cAxisBrakeModal = createModal({}, mFormat);
var gExactStopModal = createModal({}, gFormat); // modal group for exact stop codes
var tailStockModal = createModal({}, mFormat);

// fixed settings
var firstFeedParameter = 100;
var usePolarCircular = false;

var WARNING_WORK_OFFSET = 0;
var WARNING_REPEAT_TAPPING = 1;

var SPINDLE_MAIN = 0;
var SPINDLE_SUB = 1;
var SPINDLE_LIVE = 2;

// collected state
var sequenceNumber;
var currentWorkOffset;
var optionalSection = false;
var forceSpindleSpeed = false;
var activeMovements; // do not use by default
var currentFeedId;
var forceXZCMode = false; // forces XZC output, activated by Action:useXZCMode
var forcePolarMode; // force Polar output, activated by Action:usePolarMode
var useABCPrepositioning = true; // disable to use G253
var bestABCIndex = undefined;
var partCutoff = false;
var ejectRoutine = false;
var g100Mirroring = false;
var g14IsActive = false;
var retracted = new Array(false, false, false); // specifies that the tool has been retracted to the safe plane

// used to convert blocks to optional for safeStartAllOperations, might get used outside of onSection
var skipBlock = false;
var operationNeedsSafeStart = false;

var machineState = {
  liveToolIsActive              : undefined,
  cAxisIsEngaged                : undefined,
  machiningDirection            : undefined,
  mainSpindleIsActive           : undefined,
  subSpindleIsActive            : undefined,
  mainSpindleBrakeIsActive      : undefined,
  subSpindleBrakeIsActive       : undefined,
  tailstockIsActive             : undefined,
  usePolarMode                  : undefined,
  useXZCMode                    : undefined,
  axialCenterDrilling           : undefined,
  tapping                       : undefined,
  currentBAxisOrientationTurning: new Vector(0, 0, 0),
  feedPerRevolution             : undefined,
  stockTransferIsActive         : false
};

/** G/M codes setup */
function getCode(code) {
  switch (code) {
  case "PART_CATCHER_ON":
    return mFormat.format(36);
  case "PART_CATCHER_OFF":
    return mFormat.format(37);
  case "TAILSTOCK_ON":
    machineState.tailstockIsActive = true;
    return mFormat.format(21);
  case "TAILSTOCK_OFF":
    machineState.tailstockIsActive = false;
    return mFormat.format(22);
  case "ENGAGE_C_AXIS":
    if (currentSection.spindle == SPINDLE_PRIMARY && gotLiveTooling) {
      machineState.cAxisIsEngaged = true;
      return cAxisEngageModal.format(154);
    } else {
      return "";
    }
  case "DISENGAGE_C_AXIS":
    if (currentSection.spindle == SPINDLE_PRIMARY && gotLiveTooling) {
      machineState.cAxisIsEngaged = false;
      return cAxisEngageModal.format(155);
    } else {
      return "";
    }
  case "POLAR_INTERPOLATION_ON":
    return gPolarModal.format(112);
  case "POLAR_INTERPOLATION_OFF":
    return gPolarModal.format(113);
  case "STOP_SPINDLE":
    if (machineState.liveToolIsActive) {
      machineState.liveToolIsActive = false;
      return mFormat.format(135);
    } else if (machineState.mainSpindleIsActive) {
      machineState.mainSpindleIsActive = false;
      return mFormat.format(5);
    } else if (machineState.subSpindleIsActive) {
      return getCode("STOP_SUB_SPINDLE");
    } else {
      return undefined;
    }
  case "STOP_SUB_SPINDLE":
    machineState.subSpindleIsActive = false;
    return mFormat.format(g14IsActive ? 5 : 145);
  case "START_LIVE_TOOL_CW":
    machineState.liveToolIsActive = true;
    return mFormat.format(133);
  case "START_LIVE_TOOL_CCW":
    machineState.liveToolIsActive = true;
    return mFormat.format(134);
  case "START_MAIN_SPINDLE_CW":
    machineState.mainSpindleIsActive = true;
    return mFormat.format(3);
  case "START_MAIN_SPINDLE_CCW":
    machineState.mainSpindleIsActive = true;
    return mFormat.format(4);
  case "START_SUB_SPINDLE_CW":
    machineState.subSpindleIsActive = true;
    return mFormat.format(g14IsActive ? 3 : 143);
  case "START_SUB_SPINDLE_CCW":
    machineState.subSpindleIsActive = true;
    return mFormat.format(g14IsActive ? 4 : 144);
  case "MAIN_SPINDLE_BRAKE_ON":
    machineState.mainSpindleBrakeIsActive = true;
    return cAxisBrakeModal.format(14);
  case "MAIN_SPINDLE_BRAKE_OFF":
    machineState.mainSpindleBrakeIsActive = false;
    return cAxisBrakeModal.format(15);
  case "SUB_SPINDLE_BRAKE_ON":
    machineState.subSpindleBrakeIsActive = true;
    return cAxisBrakeModal.format(g14IsActive ? 14 : 114);
  case "SUB_SPINDLE_BRAKE_OFF":
    machineState.subSpindleBrakeIsActive = false;
    return cAxisBrakeModal.format(g14IsActive ? 15 : 115);
  case "FEED_MODE_UNIT_REV":
    machineState.feedPerRevolution = true;
    return gFeedModeModal.format(99);
  case "FEED_MODE_UNIT_MIN":
    machineState.feedPerRevolution = false;
    return gFeedModeModal.format(98);
  case "CONSTANT_SURFACE_SPEED_ON":
    return gSpindleModeModal.format(96);
  case "CONSTANT_SURFACE_SPEED_OFF":
    return gSpindleModeModal.format(97);
  case "MAINSPINDLE_AIR_BLAST_ON":
    return mFormat.format(12);
  case "MAINSPINDLE_AIR_BLAST_OFF":
    return mFormat.format(13);
  case "SUBSPINDLE_AIR_BLAST_ON":
    return mFormat.format(112);
  case "SUBSPINDLE_AIR_BLAST_OFF":
    return mFormat.format(113);
  case "CLAMP_PRIMARY_CHUCK":
    return mFormat.format(10);
  case "UNCLAMP_PRIMARY_CHUCK":
    return mFormat.format(11);
  case "CLAMP_SECONDARY_CHUCK":
    return mFormat.format(110);
  case "UNCLAMP_SECONDARY_CHUCK":
    return mFormat.format(111);
  case "SPINDLE_SYNCHRONIZATION_ON":
    machineState.spindleSynchronizationIsActive = true;
    return gSynchronizedSpindleModal.format(199);
  case "SPINDLE_SYNCHRONIZATION_OFF":
    machineState.spindleSynchronizationIsActive = false;
    return gSynchronizedSpindleModal.format(198);
  case "START_CHIP_TRANSPORT":
    return mFormat.format(31);
  case "STOP_CHIP_TRANSPORT":
    return mFormat.format(33);
  case "OPEN_DOOR":
    return mFormat.format(85);
  case "CLOSE_DOOR":
    return mFormat.format(86);
  default:
    error(localize("Command " + code + " is not defined."));
    return 0;
  }
}

function isSpindleSpeedDifferent() {
  if (isFirstSection()) {
    return true;
  }
  if (getPreviousSection().getTool().clockwise != tool.clockwise) {
    return true;
  }
  if (tool.getSpindleMode() == SPINDLE_CONSTANT_SURFACE_SPEED) {
    if ((getPreviousSection().getTool().getSpindleMode() != SPINDLE_CONSTANT_SURFACE_SPEED) ||
        rpmFormat.areDifferent(getPreviousSection().getTool().surfaceSpeed, tool.surfaceSpeed)) {
      return true;
    }
  } else {
    if ((getPreviousSection().getTool().getSpindleMode() != SPINDLE_CONSTANT_SPINDLE_SPEED) ||
        rpmFormat.areDifferent(getPreviousSection().getTool().spindleRPM, spindleSpeed)) {
      return true;
    }
  }
  return false;
}

function onSpindleSpeed(spindleSpeed) {
  if ((sOutput.getCurrent() != Number.POSITIVE_INFINITY) && rpmFormat.areDifferent(spindleSpeed, sOutput.getCurrent())) { // avoid redundant output of spindle speed
    startSpindle(false, getFramePosition(currentSection.getInitialPosition()), spindleSpeed);
  }
  if ((pOutput.getCurrent() != Number.POSITIVE_INFINITY) && rpmFormat.areDifferent(spindleSpeed, pOutput.getCurrent())) { // avoid redundant output of spindle speed
    startSpindle(false, getFramePosition(currentSection.getInitialPosition()), spindleSpeed);
  }
}

function startSpindle(forceRPMMode, initialPosition, rpm) {
  var _skipBlock = skipBlock;
  var _spindleSpeed = spindleSpeed;
  if (rpm !== undefined) {
    _spindleSpeed = rpm;
  }

  var useConstantSurfaceSpeed = currentSection.getTool().getSpindleMode() == SPINDLE_CONSTANT_SURFACE_SPEED;
  var maxSpeed = (currentSection.spindle == SPINDLE_SECONDARY) ? subMaximumSpindleSpeed : getProperty("maximumSpindleSpeed");
  var maximumSpindleSpeed = (tool.maximumSpindleSpeed > 0) ? Math.min(tool.maximumSpindleSpeed, maxSpeed) : maxSpeed;
  if (useConstantSurfaceSpeed && !forceRPMMode) {
    skipBlock = _skipBlock;
    writeBlock(gFormat.format(50), sOutput.format(maximumSpindleSpeed));
  } else if (!isFirstSection()) { // maximum spindle speed needs to be set when switching from SFM to RPM
    var prevConstantSurfaceSpeed = getPreviousSection().getTool().getSpindleMode() == SPINDLE_CONSTANT_SURFACE_SPEED;
    if (prevConstantSurfaceSpeed && !useConstantSurfaceSpeed) {
      writeBlock(gFormat.format(50), sOutput.format(maxSpeed));
    }
  }

  gSpindleModeModal.reset();
  skipBlock = _skipBlock;
  if (useConstantSurfaceSpeed && !forceRPMMode) {
    writeBlock(getCode("CONSTANT_SURFACE_SPEED_ON"));
  } else {
    writeBlock(getCode("CONSTANT_SURFACE_SPEED_OFF"));
  }

  _spindleSpeed = useConstantSurfaceSpeed ? tool.surfaceSpeed * ((unit == MM) ? 1 / 1000.0 : 1 / 12.0) : _spindleSpeed;
  if (useConstantSurfaceSpeed && forceRPMMode) { // RPM mode is forced until move to initial position
    if (xFormat.getResultingValue(initialPosition.x) == 0) {
      _spindleSpeed = maximumSpindleSpeed;
    } else {
      _spindleSpeed = Math.min((_spindleSpeed * ((unit == MM) ? 1000.0 : 12.0) / (Math.PI * Math.abs(initialPosition.x * 2))), maximumSpindleSpeed);
    }
  }
  switch (currentSection.spindle) {
  case SPINDLE_PRIMARY: // main spindle
    if (machineState.isTurningOperation || machineState.axialCenterDrilling) { // turning main spindle
      skipBlock = _skipBlock;
      writeBlock(
        sOutput.format(_spindleSpeed),
        conditional(!machineState.tapping, tool.clockwise ? getCode("START_MAIN_SPINDLE_CW") : getCode("START_MAIN_SPINDLE_CCW"))
      );
    } else { // milling main spindle
      skipBlock = _skipBlock;
      writeBlock(
        (machineState.tapping ? sOutput.format(spindleSpeed) : pOutput.format(_spindleSpeed)),
        conditional(!machineState.tapping, tool.clockwise ? getCode("START_LIVE_TOOL_CW") : getCode("START_LIVE_TOOL_CCW"))
      );
    }
    break;
  case SPINDLE_SECONDARY: // sub spindle
    if (!gotSecondarySpindle) {
      error(localize("Secondary spindle is not available."));
      return;
    }
    if (machineState.isTurningOperation || machineState.axialCenterDrilling) { // turning sub spindle
      gSpindleModeModal.reset();
      skipBlock = _skipBlock;
      writeBlock(
        sOutput.format(_spindleSpeed),
        conditional(!machineState.tapping, tool.clockwise ? getCode("START_SUB_SPINDLE_CW") : getCode("START_SUB_SPINDLE_CCW"))
      );
    } else { // milling sub spindle
      skipBlock = _skipBlock;
      writeBlock(pOutput.format(_spindleSpeed), tool.clockwise ? getCode("START_LIVE_TOOL_CW") : getCode("START_LIVE_TOOL_CCW"));
    }
    break;
  }

  if (getProperty("useSSV")) {
    if (machineState.isTurningOperation && hasParameter("operation-strategy") && getParameter("operation-strategy") != "turningThread") {
      skipBlock = _skipBlock;
      writeBlock(ssvModal.format(38));
    }
  }
}

/** Write retract in XYZB. */
var B = 4;
function writeRetract() {
  var words = []; // store all retracted axes in an array
  for (var i = 0; i < arguments.length; ++i) {
    // define the axes to move
    switch (arguments[i]) {
    case X:
      words.push("X" + xFormat.format(machineConfiguration.getHomePositionX()));
      retracted[X] = true;
      break;
    case Y:
      words.push("Y" + yFormat.format(machineConfiguration.getHomePositionY()));
      retracted[Y] = true;
      break;
    case Z:
      words.push("Z" + zFormat.format((currentSection.spindle == SPINDLE_SECONDARY) ? getProperty("g53HomePositionSubZ") : machineConfiguration.getRetractPlane()));
      retracted[Z] = true;
      break;
    case B:
      words.push("B" + abcFormat.format(0));
      currentMachineABC.setY(0);
      if (getCurrentSectionId() != -1) {
        setCurrentABC(currentMachineABC);
      }
      break;
    }
  }

  gMotionModal.reset();
  writeBlock(gFormat.format(53), gMotionModal.format(0), words);
}

/** Returns the modulus. */
function getModulus(x, y) {
  return Math.sqrt(x * x + y * y);
}

/**
  Returns the C rotation for the given X and Y coordinates.
*/
function getC(x, y) {
  var direction;
  if (Vector.dot(machineConfiguration.getAxisU().getAxis(), new Vector(0, 0, 1)) != 0) {
    direction = (machineConfiguration.getAxisU().getAxis().getCoordinate(2) >= 0) ? 1 : -1; // C-axis is the U-axis
  } else {
    direction = (machineConfiguration.getAxisV().getAxis().getCoordinate(2) >= 0) ? 1 : -1; // C-axis is the V-axis
  }

  return Math.atan2(y, x) * direction;
}

/**
  Returns the C rotation for the given X and Y coordinates in the desired rotary direction.
*/
function getCClosest(x, y, _c, clockwise) {
  if (_c == Number.POSITIVE_INFINITY) {
    _c = 0; // undefined
  }
  if (!xFormat.isSignificant(x) && !yFormat.isSignificant(y)) { // keep C if XY is on center
    return _c;
  }
  var c = getC(x, y);
  if (clockwise != undefined) {
    if (clockwise) {
      while (c < _c) {
        c += Math.PI * 2;
      }
    } else {
      while (c > _c) {
        c -= Math.PI * 2;
      }
    }
  } else {
    min = _c - Math.PI;
    max = _c + Math.PI;
    while (c < min) {
      c += Math.PI * 2;
    }
    while (c > max) {
      c -= Math.PI * 2;
    }
  }
  return c;
}

function getCWithinRange(x, y, _c, clockwise) {
  var c = getCClosest(x, y, _c, clockwise);

  var cyclicLimit;
  var cyclic;
  if (Vector.dot(machineConfiguration.getAxisU().getAxis(), new Vector(0, 0, 1)) != 0) {
    // C-axis is the U-axis
    cyclicLimit = machineConfiguration.getAxisU().getRange();
    cyclic = machineConfiguration.getAxisU().isCyclic();
  } else if (Vector.dot(machineConfiguration.getAxisV().getAxis(), new Vector(0, 0, 1)) != 0) {
    // C-axis is the V-axis
    cyclicLimit = machineConfiguration.getAxisV().getRange();
    cyclic = machineConfiguration.getAxisV().isCyclic();
  } else {
    error(localize("Unsupported rotary axis direction."));
    return 0;
  }

  // see if rewind is required
  forceRewind = false;
  if (cyclic) {
    return c;
  }
  if ((cFormat.getResultingValue(c) < abcFormat.getResultingValue(cyclicLimit[0])) || (cFormat.getResultingValue(c) > abcFormat.getResultingValue(cyclicLimit[1]))) {
    if (!cyclic) {
      forceRewind = true;
    }
    c = getCClosest(x, y, 0); // find closest C to 0
    if ((cFormat.getResultingValue(c) < abcFormat.getResultingValue(cyclicLimit[0])) || (cFormat.getResultingValue(c) > abcFormat.getResultingValue(cyclicLimit[1]))) {
      var midRange = cyclicLimit[0] + (cyclicLimit[1] - cyclicLimit[0]) / 2;
      c = getCClosest(x, y, midRange); // find closest C to midRange
    }
    if ((cFormat.getResultingValue(c) < abcFormat.getResultingValue(cyclicLimit[0])) || (cFormat.getResultingValue(c) > abcFormat.getResultingValue(cyclicLimit[1]))) {
      error(localize("Unable to find C-axis position within the defined range."));
      return 0;
    }
  }
  return c;
}

/**
  Returns the desired tolerance for the given section.
*/
function getTolerance() {
  var t = tolerance;
  if (hasParameter("operation:tolerance")) {
    if (t > 0) {
      t = Math.min(t, getParameter("operation:tolerance"));
    } else {
      t = getParameter("operation:tolerance");
    }
  }
  return t;
}

/**
  Writes the specified block.
*/
function writeBlock() {
  var text = formatWords(arguments);
  if (!text) {
    skipBlock = false;
    return;
  }
  if (getProperty("showSequenceNumbers") == "true") {
    if (sequenceNumber > 99999) {
      sequenceNumber = getProperty("sequenceNumberStart");
    }
    if (optionalSection || skipBlock) {
      if (text) {
        writeWords("/", "N" + sequenceNumber, text);
      }
    } else {
      writeWords2("N" + sequenceNumber, arguments);
    }
    sequenceNumber += getProperty("sequenceNumberIncrement");
  } else {
    if (optionalSection || skipBlock) {
      writeWords2("/", arguments);
    } else {
      writeWords(arguments);
    }
  }
  skipBlock = false;
}

/**
  Writes the specified optional block.
*/
function writeOptionalBlock() {
  if (getProperty("showSequenceNumbers") == "true") {
    var words = formatWords(arguments);
    if (words) {
      writeWords("/", "N" + sequenceNumber, words);
      sequenceNumber += getProperty("sequenceNumberIncrement");
    }
  } else {
    writeWords2("/", arguments);
  }
}

function writeDebug(_text) {
  writeComment("DEBUG - " + _text);
  log("DEBUG - " + _text);
}

function formatComment(text) {
  return "(" + String(text).replace(/[()]/g, "") + ")";
}

/**
  Writes the specified block - used for tool changes only.
*/
function writeToolBlock() {
  var show = getProperty("showSequenceNumbers");
  setProperty("showSequenceNumbers", (show == "true" || show == "toolChange") ? "true" : "false");
  writeBlock(arguments);
  setProperty("showSequenceNumbers", show);
}

/**
  Output a comment.
*/
function writeComment(text) {
  writeln(formatComment(text));
}

function getB(abc, section) {
  if (section.spindle == SPINDLE_PRIMARY) {
    return abc.y;
  } else {
    return Math.PI - abc.y;
  }
}

// Start of machine configuration logic
var compensateToolLength = false; // add the tool length to the pivot distance for nonTCP rotary heads

// internal variables, do not change
var receivedMachineConfiguration;
var operationSupportsTCP;
var multiAxisFeedrate;

function activateMachine() {
  // disable unsupported rotary axes output
  if (!machineConfiguration.isMachineCoordinate(0) && (typeof aOutput != "undefined")) {
    aOutput.disable();
  }
  if (!machineConfiguration.isMachineCoordinate(1) && (typeof bOutput != "undefined")) {
    bOutput.disable();
  }
  if (!machineConfiguration.isMachineCoordinate(2) && (typeof cOutput != "undefined")) {
    cOutput.disable();
  }

  // setup usage of multiAxisFeatures
  useMultiAxisFeatures = getProperty("useMultiAxisFeatures") != undefined ? getProperty("useMultiAxisFeatures") :
    (typeof useMultiAxisFeatures != "undefined" ? useMultiAxisFeatures : false);
  useABCPrepositioning = getProperty("useABCPrepositioning") != undefined ? getProperty("useABCPrepositioning") :
    (typeof useABCPrepositioning != "undefined" ? useABCPrepositioning : false);

  if (!machineConfiguration.isMultiAxisConfiguration()) {
    return; // don't need to modify any settings for 3-axis machines
  }

  // save multi-axis feedrate settings from machine configuration
  var mode = machineConfiguration.getMultiAxisFeedrateMode();
  var type = mode == FEED_INVERSE_TIME ? machineConfiguration.getMultiAxisFeedrateInverseTimeUnits() :
    (mode == FEED_DPM ? machineConfiguration.getMultiAxisFeedrateDPMType() : DPM_STANDARD);
  multiAxisFeedrate = {
    mode     : mode,
    maximum  : machineConfiguration.getMultiAxisFeedrateMaximum(),
    type     : type,
    tolerance: mode == FEED_DPM ? machineConfiguration.getMultiAxisFeedrateOutputTolerance() : 0,
    bpwRatio : mode == FEED_DPM ? machineConfiguration.getMultiAxisFeedrateBpwRatio() : 1
  };

  // setup of retract/reconfigure  TAG: Only needed until post kernel supports these machine config settings
  if (receivedMachineConfiguration && machineConfiguration.performRewinds()) {
    safeRetractDistance = machineConfiguration.getSafeRetractDistance();
    safePlungeFeed = machineConfiguration.getSafePlungeFeedrate();
    safeRetractFeed = machineConfiguration.getSafeRetractFeedrate();
  }
  if (typeof safeRetractDistance == "number" && getProperty("safeRetractDistance") != undefined && getProperty("safeRetractDistance") != 0) {
    safeRetractDistance = getProperty("safeRetractDistance");
  }

  if (machineConfiguration.isHeadConfiguration()) {
    compensateToolLength = typeof compensateToolLength == "undefined" ? false : compensateToolLength;
  }

  if (typeof gotSecondarySpindle == "undefined" || !gotSecondarySpindle) {
    if (machineConfiguration.isHeadConfiguration() && compensateToolLength) {
      for (var i = 0; i < getNumberOfSections(); ++i) {
        var section = getSection(i);
        if (section.isMultiAxis()) {
          machineConfiguration.setToolLength(getBodyLength(section.getTool())); // define the tool length for head adjustments
          section.optimizeMachineAnglesByMachine(machineConfiguration, OPTIMIZE_AXIS);
        }
      }
    } else {
      optimizeMachineAngles2(OPTIMIZE_AXIS);
    }
  }
}

function getBodyLength(tool) {
  for (var i = 0; i < getNumberOfSections(); ++i) {
    var section = getSection(i);
    if (tool.number == section.getTool().number) {
      return section.getParameter("operation:tool_overallLength", tool.bodyLength + tool.holderLength);
    }
  }
  return tool.bodyLength + tool.holderLength;
}

function defineMachine() {
  var useTCP = true;
  var gotCAxis = gotLiveTooling;
  if (receivedMachineConfiguration) {
    var bAxis = machineConfiguration.getAxisU();
    var cAxis = machineConfiguration.getAxisV();
    if ((!bAxis.isEnabled() || bAxis.getCoordinate() != 1 || !isSameDirection(bAxis.getAxis().abs, new Vector(0, 1, 0)) || !bAxis.isHead()) ||
        (!cAxis.isEnabled() || cAxis.getCoordinate() != 2 || !isSameDirection(cAxis.getAxis().abs, new Vector(0, 0, 1)) || !cAxis.isTable())) {
      warning(localize("The provided CAM machine configuration is overwritten by the postprocessor."));
      receivedMachineConfiguration = false;
    }
  }

  if (gotSecondarySpindle) {
    error(localize("This post processor has not been optimized for use with a secondary spindle"));
    return;
  }

  if (!receivedMachineConfiguration) {
    var bAxisMain = createAxis({coordinate:1, table:false, axis:[0, -1, 0], range:[-90.001, 8.001], tcp:useTCP, preference:-1});
    var cAxisMain = createAxis({coordinate:2, table:true, axis:[0, 0, 1], cyclic:true, preference:0, tcp:useTCP, reset:1});
    if (gotSecondarySpindle) {
      var bAxisSub = createAxis({coordinate:1, table:false, axis:[0, -1, 0], range:[-90.001, 8.001], tcp:useTCP, preference:-1});
      var cAxisSub = createAxis({coordinate:2, table:true, axis:[0, 0, 1], cyclic:true, preference:0, tcp:useTCP, reset:1});
      machineConfigurationMainSpindle = gotCAxis ? gotBAxis ? new MachineConfiguration(bAxisMain, cAxisMain) : new MachineConfiguration(cAxisMain) : new MachineConfiguration();
      machineConfigurationSubSpindle =  gotCAxis ? gotBAxis ? new MachineConfiguration(bAxisSub, cAxisSub) : new MachineConfiguration(cAxisSub) : new MachineConfiguration();
      machineConfiguration = new MachineConfiguration(bAxisMain, cAxisMain);
    } else {
      machineConfiguration = gotCAxis ? gotBAxis ? new MachineConfiguration(bAxisMain, cAxisMain) : new MachineConfiguration(cAxisMain) : new MachineConfiguration();
      machineConfiguration.setSpindleAxis(new Vector(1, 0, 0)); // set the spindle axis depending on B0 orientation
    }
  }

  machineConfiguration.setVendor("HAAS");
  machineConfiguration.setModel(description);

  if (!receivedMachineConfiguration) {
    // multiaxis settings
    if (machineConfiguration.isHeadConfiguration()) {
      machineConfiguration.setVirtualTooltip(false); // translate the pivot point to the virtual tool tip for nonTCP rotary heads
    }

    // retract / reconfigure
    var performRewinds = false; // set to true to enable the rewind/reconfigure logic
    if (performRewinds) {
      machineConfiguration.enableMachineRewinds(); // enables the retract/reconfigure logic
      safeRetractDistance = (unit == IN) ? 1 : 25; // additional distance to retract out of stock, can be overridden with a property
      safeRetractFeed = (unit == IN) ? 20 : 500; // retract feed rate
      safePlungeFeed = (unit == IN) ? 10 : 250; // plunge feed rate
      machineConfiguration.setSafeRetractDistance(safeRetractDistance);
      machineConfiguration.setSafeRetractFeedrate(safeRetractFeed);
      machineConfiguration.setSafePlungeFeedrate(safePlungeFeed);
      var stockExpansion = new Vector(toPreciseUnit(0.1, IN), toPreciseUnit(0.1, IN), toPreciseUnit(0.1, IN)); // expand stock XYZ values
      machineConfiguration.setRewindStockExpansion(stockExpansion);
    }

    // multi-axis feedrates
    if (machineConfiguration.isMultiAxisConfiguration()) {
      machineConfiguration.setMultiAxisFeedrate(
        useTCP ? FEED_FPM : FEED_INVERSE_TIME,
        9999.99, // maximum output value for inverse time feed rates
        INVERSE_MINUTES, // INVERSE_MINUTES/INVERSE_SECONDS or DPM_COMBINATION/DPM_STANDARD
        0.5, // tolerance to determine when the DPM feed has changed
        unit == MM ? 1.0 : 1.0 // ratio of rotary accuracy to linear accuracy for DPM calculations
      );
      setMachineConfiguration(machineConfiguration);
    }

    /* home positions */
    machineConfiguration.setHomePositionX(toPreciseUnit(getProperty("homePositionX"), IN));
    machineConfiguration.setHomePositionY(toPreciseUnit(getProperty("homePositionY"), IN));
    machineConfiguration.setRetractPlane(toPreciseUnit(getProperty("homePositionZ"), IN));
  }
}
// End of machine configuration logic

var machineConfigurationMainSpindle;
var machineConfigurationSubSpindle;

function onOpen() {
  receivedMachineConfiguration = machineConfiguration.isReceived();
  if (typeof defineMachine == "function") {
    defineMachine(); // hardcoded machine configuration
  }
  activateMachine(); // enable the machine optimizations and settings

  if (getProperty("useRadius")) {
    maximumCircularSweep = toRad(90); // avoid potential center calculation errors for CNC
  }

  if (getProperty("useG61")) {
    gExactStopModal.format(64);
  }

  if (!gotYAxis) {
    yOutput.disable();
  }

  if (highFeedrate <= 0) {
    error(localize("You must set 'highFeedrate' because axes are not synchronized for rapid traversal."));
    return;
  }

  if (!getProperty("separateWordsWithSpace")) {
    setWordSeparator("");
  }

  sequenceNumber = getProperty("sequenceNumberStart");
  writeln("%");

  if (programName) {
    var programId;
    try {
      programId = getAsInt(programName);
    } catch (e) {
      error(localize("Program name must be a number."));
      return;
    }
    if (!((programId >= 1) && (programId <= 99999))) {
      error(localize("Program number is out of range."));
      return;
    }
    var oFormat = createFormat({width:5, zeropad:true, decimals:0});
    if (programComment) {
      writeln("O" + oFormat.format(programId) + " (" + filterText(String(programComment).toUpperCase(), permittedCommentChars) + ")");
    } else {
      writeln("O" + oFormat.format(programId));
    }
  } else {
    error(localize("Program name has not been specified."));
    return;
  }

  if (getProperty("writeVersion")) {
    if ((typeof getHeaderVersion == "function") && getHeaderVersion()) {
      writeComment(localize("post version") + ": " + getHeaderVersion());
    }
    if ((typeof getHeaderDate == "function") && getHeaderDate()) {
      writeComment(localize("post modified") + ": " + getHeaderDate());
    }
  }

  // dump machine configuration
  var vendor = machineConfiguration.getVendor();
  var model = machineConfiguration.getModel();
  var description = machineConfiguration.getDescription();

  if (getProperty("writeMachine") && (vendor || model || description)) {
    writeComment(localize("Machine"));
    if (vendor) {
      writeComment("  " + localize("vendor") + ": " + vendor);
    }
    if (model) {
      writeComment("  " + localize("model") + ": " + model);
    }
    if (description) {
      writeComment("  " + localize("description") + ": "  + description);
    }
  }

  // dump tool information
  if (getProperty("writeTools")) {
    var zRanges = {};
    if (is3D()) {
      var numberOfSections = getNumberOfSections();
      for (var i = 0; i < numberOfSections; ++i) {
        var section = getSection(i);
        var zRange = section.getGlobalZRange();
        var tool = section.getTool();
        if (zRanges[tool.number]) {
          zRanges[tool.number].expandToRange(zRange);
        } else {
          zRanges[tool.number] = zRange;
        }
      }
    }

    var tools = getToolTable();
    if (tools.getNumberOfTools() > 0) {
      for (var i = 0; i < tools.getNumberOfTools(); ++i) {
        var tool = tools.getTool(i);
        var compensationOffset = tool.isTurningTool() ? tool.compensationOffset : tool.lengthOffset;
        var comment = "T" + toolFormat.format(tool.number * 100 + compensationOffset % 100) + " " +
          (tool.diameter != 0 ? "D=" + spatialFormat.format(tool.diameter) + " " : "") +
          (tool.isTurningTool() ? localize("NR") + "=" + spatialFormat.format(tool.noseRadius) : localize("CR") + "=" + spatialFormat.format(tool.cornerRadius)) +
          (tool.taperAngle > 0 && (tool.taperAngle < Math.PI) ? " " + localize("TAPER") + "=" + taperFormat.format(tool.taperAngle) + localize("deg") : "") +
          (zRanges[tool.number] ? " - " + localize("ZMIN") + "=" + spatialFormat.format(zRanges[tool.number].getMinimum()) : "") +
          " - " + localize(getToolTypeName(tool.type));
        writeComment(comment);

        if (getProperty("useM130ToolImages")) {
          var toolRenderer = createToolRenderer();
          if (toolRenderer) {
            toolRenderer.setBackgroundColor(new Color(1, 1, 1));
            toolRenderer.setFluteColor(new Color(40.0 / 255, 40.0 / 255, 40.0 / 255));
            toolRenderer.setShoulderColor(new Color(80.0 / 255, 80.0 / 255, 80.0 / 255));
            toolRenderer.setShaftColor(new Color(80.0 / 255, 80.0 / 255, 80.0 / 255));
            toolRenderer.setHolderColor(new Color(40.0 / 255, 40.0 / 255, 40.0 / 255));
            if (i % 2 == 0) {
              toolRenderer.setBackgroundColor(new Color(1, 1, 1));
            } else {
              toolRenderer.setBackgroundColor(new Color(240 / 255.0, 240 / 255.0, 240 / 255.0));
            }
            var path = "tool" + tool.number + ".png";
            var width = 400;
            var height = 532;
            toolRenderer.exportAs(path, "image/png", tool, width, height);
          }
        }
      }
    }
  }

  if (false) {
    // check for duplicate tool number
    for (var i = 0; i < getNumberOfSections(); ++i) {
      var sectioni = getSection(i);
      var tooli = sectioni.getTool();
      for (var j = i + 1; j < getNumberOfSections(); ++j) {
        var sectionj = getSection(j);
        var toolj = sectionj.getTool();
        if (tooli.number == toolj.number) {
          if (spatialFormat.areDifferent(tooli.diameter, toolj.diameter) ||
              spatialFormat.areDifferent(tooli.cornerRadius, toolj.cornerRadius) ||
              abcFormat.areDifferent(tooli.taperAngle, toolj.taperAngle) ||
              (tooli.numberOfFlutes != toolj.numberOfFlutes)) {
            error(
              subst(
                localize("Using the same tool number for different cutter geometry for operation '%1' and '%2'."),
                sectioni.hasParameter("operation-comment") ? sectioni.getParameter("operation-comment") : ("#" + (i + 1)),
                sectionj.hasParameter("operation-comment") ? sectionj.getParameter("operation-comment") : ("#" + (j + 1))
              )
            );
            return;
          }
        }
      }
    }
  }

  if ((getNumberOfSections() > 0) && (getSection(0).workOffset == 0)) {
    for (var i = 0; i < getNumberOfSections(); ++i) {
      if (getSection(i).workOffset > 0) {
        error(localize("Using multiple work offsets is not possible if the initial work offset is 0."));
        return;
      }
    }
  }

  // support program looping for bar work
  if (getProperty("looping")) {
    if (getProperty("numberOfRepeats") < 1) {
      error(localize("numberOfRepeats must be greater than 0."));
      return;
    }
    if (sequenceNumber == 1) {
      sequenceNumber++;
    }
    writeln("");
    writeln("");
    writeComment(localize("Local Looping"));
    writeln("");
    writeBlock(mFormat.format(97), "P1", "L" + getProperty("numberOfRepeats"));
    onCommand(COMMAND_OPEN_DOOR);
    writeBlock(mFormat.format(30));
    writeln("");
    writeln("");
    writeln("N1 (START MAIN PROGRAM)");
  }

  // absolute coordinates and feed per min
  writeBlock(gAbsIncModal.format(390), getCode("FEED_MODE_UNIT_MIN"), gPlaneModal.format(18));

  switch (unit) {
  case IN:
    writeBlock(gUnitModal.format(20));
    break;
  case MM:
    writeBlock(gUnitModal.format(21));
    break;
  }

  var xScale = 1;
  switch (getProperty("radiusMode")) {
  case "radius":
    xScale = 1;
    break;
  case "diameter":
    xScale = 2;
    break;
  case "g171":
    xScale = 1;
    writeBlock(gFormat.format(171));
    break;
  case "g172":
    xScale = 2;
    writeBlock(gFormat.format(172));
    break;
  }
  xFormat = createFormat({decimals:(unit == MM ? 3 : 4), forceDecimal:true, scale:xScale});
  xOutput = createVariable({onchange:function() {retracted[X] = false;}, prefix:"X"}, xFormat);

  onCommand(COMMAND_CLOSE_DOOR);

  var usesPrimarySpindle = false;
  var usesSecondarySpindle = false;
  for (var i = 0; i < getNumberOfSections(); ++i) {
    var section = getSection(i);
    if (section.getType() != TYPE_TURNING) {
      continue;
    }
    switch (section.spindle) {
    case SPINDLE_PRIMARY:
      usesPrimarySpindle = true;
      break;
    case SPINDLE_SECONDARY:
      usesSecondarySpindle = true;
      break;
    }
  }

  writeBlock(gFormat.format(50), sOutput.format(getSection(0).spindle == SPINDLE_PRIMARY ? getProperty("maximumSpindleSpeed") : subMaximumSpindleSpeed));
  sOutput.reset();

  if (getProperty("gotChipConveyor")) {
    onCommand(COMMAND_START_CHIP_TRANSPORT);
  }

  if (gotSecondarySpindle) {
    var b = getSection(0).spindle == SPINDLE_PRIMARY ? g53HomePositionSubZ : g53WorkPositionSub;
    writeBlock(gFormat.format(53), gMotionModal.format(0), "B" + spatialFormat.format(b)); // retract Sub Spindle if applicable
  }

  // automatically eject part at end of program
  if (getProperty("autoEject")) {
    ejectRoutine = true;
  }
/*
  if (getProperty("useM97")) {
    for (var i = 0; i < getNumberOfSections(); ++i) {
      var section = getSection(i);
      writeBlock(mFormat.format(97), pFormat.format(section.getId() + getProperty("sequenceNumberStart")), conditional(section.hasParameter("operation-comment"), "(" + section.getParameter("operation-comment") + ")"));
    }
    writeBlock(mFormat.format(30));
    if (getProperty("showSequenceNumbers") && getProperty("useM97")) {
      error(localize("Properties 'showSequenceNumbers' and 'useM97' cannot be active together at the same time."));
      return;
    }
  }
*/
}

function onComment(message) {
  writeComment(message);
}

/** Force output of X, Y, and Z. */
function forceXYZ() {
  xOutput.reset();
  yOutput.reset();
  zOutput.reset();
}

/** Force output of A, B, and C. */
function forceABC() {
  aOutput.reset();
  bOutput.reset();
  cOutput.reset();
}

function forceFeed() {
  currentFeedId = undefined;
  previousDPMFeed = 0;
  feedOutput.reset();
}

/** Force output of X, Y, Z, A, B, C, and F on next output. */
function forceAny() {
  forceXYZ();
  forceABC();
  forceFeed();
}

// Start of smoothing logic
var smoothingSettings = {
  roughing              : 1, // roughing level for smoothing in automatic mode
  semi                  : 2, // semi-roughing level for smoothing in automatic mode
  semifinishing         : 2, // semi-finishing level for smoothing in automatic mode
  finishing             : 3, // finishing level for smoothing in automatic mode
  thresholdRoughing     : toPreciseUnit(0.5, MM), // operations with stock/tolerance above that threshold will use roughing level in automatic mode
  thresholdFinishing    : toPreciseUnit(0.05, MM), // operations with stock/tolerance below that threshold will use finishing level in automatic mode
  thresholdSemiFinishing: toPreciseUnit(0.1, MM), // operations with stock/tolerance above finishing and below threshold roughing that threshold will use semi finishing level in automatic mode

  differenceCriteria: "level", // options: "level", "tolerance", "both". Specifies criteria when output smoothing codes
  autoLevelCriteria : "stock", // use "stock" or "tolerance" to determine levels in automatic mode
  cancelCompensation: false // tool length compensation must be canceled prior to changing the smoothing level
};

// collected state below, do not edit
var smoothing = {
  cancel     : false, // cancel tool length prior to update smoothing for this operation
  isActive   : false, // the current state of smoothing
  isAllowed  : false, // smoothing is allowed for this operation
  isDifferent: false, // tells if smoothing levels/tolerances/both are different between operations
  level      : -1, // the active level of smoothing
  tolerance  : -1, // the current operation tolerance
  force      : false // smoothing needs to be forced out in this operation
};

function initializeSmoothing() {
  var previousLevel = smoothing.level;
  var previousTolerance = smoothing.tolerance;

  // determine new smoothing levels and tolerances
  smoothing.level = parseInt(getProperty("useSmoothing"), 10);
  smoothing.level = isNaN(smoothing.level) ? -1 : smoothing.level;
  smoothing.tolerance = Math.max(getParameter("operation:tolerance", smoothingSettings.thresholdFinishing), 0);

  // automatically determine smoothing level
  if (smoothing.level == 9999) {
    if (smoothingSettings.autoLevelCriteria == "stock") { // determine auto smoothing level based on stockToLeave
      var stockToLeave = spatialFormat.getResultingValue(getParameter("operation:stockToLeave", 0));
      var verticalStockToLeave = spatialFormat.getResultingValue(getParameter("operation:verticalStockToLeave", 0));
      if (((stockToLeave >= smoothingSettings.thresholdRoughing) && (verticalStockToLeave >= smoothingSettings.thresholdRoughing)) ||
          getParameter("operation:strategy", "") == "face") {
        smoothing.level = smoothingSettings.roughing; // set roughing level
      } else {
        if (((stockToLeave >= smoothingSettings.thresholdSemiFinishing) && (stockToLeave < smoothingSettings.thresholdRoughing)) &&
          ((verticalStockToLeave >= smoothingSettings.thresholdSemiFinishing) && (verticalStockToLeave  < smoothingSettings.thresholdRoughing))) {
          smoothing.level = smoothingSettings.semi; // set semi level
        } else if (((stockToLeave >= smoothingSettings.thresholdFinishing) && (stockToLeave < smoothingSettings.thresholdSemiFinishing)) &&
          ((verticalStockToLeave >= smoothingSettings.thresholdFinishing) && (verticalStockToLeave  < smoothingSettings.thresholdSemiFinishing))) {
          smoothing.level = smoothingSettings.semifinishing; // set semi-finishing level
        } else {
          smoothing.level = smoothingSettings.finishing; // set finishing level
        }
      }
    } else { // detemine auto smoothing level based on operation tolerance instead of stockToLeave
      if (smoothing.tolerance >= smoothingSettings.thresholdRoughing ||
          getParameter("operation:strategy", "") == "face") {
        smoothing.level = smoothingSettings.roughing; // set roughing level
      } else {
        if (((smoothing.tolerance >= smoothingSettings.thresholdSemiFinishing) && (smoothing.tolerance < smoothingSettings.thresholdRoughing))) {
          smoothing.level = smoothingSettings.semi; // set semi level
        } else if (((smoothing.tolerance >= smoothingSettings.thresholdFinishing) && (smoothing.tolerance < smoothingSettings.thresholdSemiFinishing))) {
          smoothing.level = smoothingSettings.semifinishing; // set semi-finishing level
        } else {
          smoothing.level = smoothingSettings.finishing; // set finishing level
        }
      }
    }
  }
  if (smoothing.level == -1) { // useSmoothing is disabled
    smoothing.isAllowed = false;
  } else { // do not output smoothing for the following operations
    smoothing.isAllowed = !(currentSection.getTool().type == TOOL_PROBE || currentSection.checkGroup(STRATEGY_DRILLING) || machineState.isTurningOperation);
  }
  if (!smoothing.isAllowed) {
    smoothing.level = -1;
    smoothing.tolerance = -1;
  }

  switch (smoothingSettings.differenceCriteria) {
  case "level":
    smoothing.isDifferent = smoothing.level != previousLevel;
    break;
  case "tolerance":
    smoothing.isDifferent = xyzFormat.areDifferent(smoothing.tolerance, previousTolerance);
    break;
  case "both":
    smoothing.isDifferent = smoothing.level != previousLevel || xyzFormat.areDifferent(smoothing.tolerance, previousTolerance);
    break;
  default:
    error(localize("Unsupported smoothing criteria."));
    return;
  }

  // tool length compensation needs to be canceled when smoothing state/level changes
  if (smoothingSettings.cancelCompensation) {
    smoothing.cancel = !isFirstSection() && smoothing.isDifferent;
  }
}

function setSmoothing(mode) {
  if (mode == smoothing.isActive && (!mode || !smoothing.isDifferent) && !smoothing.force) {
    return; // return if smoothing is already active or is not different
  }
  if (typeof lengthCompensationActive != "undefined" && smoothingSettings.cancelCompensation) {
    validate(!lengthCompensationActive, "Length compensation is active while trying to update smoothing.");
  }
  if (mode) { // enable smoothing
    writeBlock(
      gFormat.format(187),
      "P" + smoothing.level,
      conditional((smoothingSettings.differenceCriteria != "level"), "E" + spatialFormat.format(smoothing.tolerance))
    );
  } else { // disable smoothing
    writeBlock(gFormat.format(187));
  }
  smoothing.isActive = mode;
  smoothing.force = false;
  smoothing.isDifferent = false;
}
// End of smoothing logic

function FeedContext(id, description, feed) {
  this.id = id;
  this.description = description;
  this.feed = feed;
}

function getFeed(f) {
  if (activeMovements) {
    var feedContext = activeMovements[movement];
    if (feedContext != undefined) {
      if (!feedFormat.areDifferent(feedContext.feed, f)) {
        if (feedContext.id == currentFeedId) {
          return ""; // nothing has changed
        }
        forceFeed();
        currentFeedId = feedContext.id;
        return "F#" + (firstFeedParameter + feedContext.id);
      }
    }
    currentFeedId = undefined; // force Q feed next time
  }
  return feedOutput.format(f); // use feed value
}

function initializeActiveFeeds() {
  activeMovements = new Array();
  var movements = currentSection.getMovements();
  var feedPerRev = currentSection.feedMode == FEED_PER_REVOLUTION;

  var id = 0;
  var activeFeeds = new Array();
  if (hasParameter("operation:tool_feedCutting")) {
    if (movements & ((1 << MOVEMENT_CUTTING) | (1 << MOVEMENT_LINK_TRANSITION) | (1 << MOVEMENT_EXTENDED))) {
      var feedContext = new FeedContext(id, localize("Cutting"), feedPerRev ? getParameter("operation:tool_feedCuttingRel") : getParameter("operation:tool_feedCutting"));
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_CUTTING] = feedContext;
      if (!hasParameter("operation:tool_feedTransition")) {
        activeMovements[MOVEMENT_LINK_TRANSITION] = feedContext;
      }
      activeMovements[MOVEMENT_EXTENDED] = feedContext;
    }
    ++id;
    if (movements & (1 << MOVEMENT_PREDRILL)) {
      feedContext = new FeedContext(id, localize("Predrilling"), feedPerRev ? getParameter("operation:tool_feedCuttingRel") : getParameter("operation:tool_feedCutting"));
      activeMovements[MOVEMENT_PREDRILL] = feedContext;
      activeFeeds.push(feedContext);
    }
    ++id;
  }

  if (hasParameter("operation:finishFeedrate")) {
    if (movements & (1 << MOVEMENT_FINISH_CUTTING)) {
      var finishFeedrateRel;
      if (hasParameter("operation:finishFeedrateRel")) {
        finishFeedrateRel = getParameter("operation:finishFeedrateRel");
      } else if (hasParameter("operation:finishFeedratePerRevolution")) {
        finishFeedrateRel = getParameter("operation:finishFeedratePerRevolution");
      }
      var feedContext = new FeedContext(id, localize("Finish"), feedPerRev ? finishFeedrateRel : getParameter("operation:finishFeedrate"));
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_FINISH_CUTTING] = feedContext;
    }
    ++id;
  } else if (hasParameter("operation:tool_feedCutting")) {
    if (movements & (1 << MOVEMENT_FINISH_CUTTING)) {
      var feedContext = new FeedContext(id, localize("Finish"), feedPerRev ? getParameter("operation:tool_feedCuttingRel") : getParameter("operation:tool_feedCutting"));
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_FINISH_CUTTING] = feedContext;
    }
    ++id;
  }

  if (hasParameter("operation:tool_feedEntry")) {
    if (movements & (1 << MOVEMENT_LEAD_IN)) {
      var feedContext = new FeedContext(id, localize("Entry"), feedPerRev ? getParameter("operation:tool_feedEntryRel") : getParameter("operation:tool_feedEntry"));
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_LEAD_IN] = feedContext;
    }
    ++id;
  }

  if (hasParameter("operation:tool_feedExit")) {
    if (movements & (1 << MOVEMENT_LEAD_OUT)) {
      var feedContext = new FeedContext(id, localize("Exit"), feedPerRev ? getParameter("operation:tool_feedExitRel") : getParameter("operation:tool_feedExit"));
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_LEAD_OUT] = feedContext;
    }
    ++id;
  }

  if (hasParameter("operation:noEngagementFeedrate")) {
    if (movements & (1 << MOVEMENT_LINK_DIRECT)) {
      var feedContext = new FeedContext(id, localize("Direct"), feedPerRev ? getParameter("operation:noEngagementFeedrateRel") : getParameter("operation:noEngagementFeedrate"));
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_LINK_DIRECT] = feedContext;
    }
    ++id;
  } else if (hasParameter("operation:tool_feedCutting") &&
             hasParameter("operation:tool_feedEntry") &&
             hasParameter("operation:tool_feedExit")) {
    if (movements & (1 << MOVEMENT_LINK_DIRECT)) {
      var feedContext = new FeedContext(
        id,
        localize("Direct"),
        Math.max(
          feedPerRev ? getParameter("operation:tool_feedCuttingRel") : getParameter("operation:tool_feedCutting"),
          feedPerRev ? getParameter("operation:tool_feedEntryRel") : getParameter("operation:tool_feedEntry"),
          feedPerRev ? getParameter("operation:tool_feedExitRel") : getParameter("operation:tool_feedExit")
        )
      );
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_LINK_DIRECT] = feedContext;
    }
    ++id;
  }

  if (hasParameter("operation:reducedFeedrate")) {
    if (movements & (1 << MOVEMENT_REDUCED)) {
      var feedContext = new FeedContext(id, localize("Reduced"), feedPerRev ? getParameter("operation:reducedFeedrateRel") : getParameter("operation:reducedFeedrate"));
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_REDUCED] = feedContext;
    }
    ++id;
  }

  if (hasParameter("operation:tool_feedRamp")) {
    if (movements & ((1 << MOVEMENT_RAMP) | (1 << MOVEMENT_RAMP_HELIX) | (1 << MOVEMENT_RAMP_PROFILE) | (1 << MOVEMENT_RAMP_ZIG_ZAG))) {
      var feedContext = new FeedContext(id, localize("Ramping"), feedPerRev ? getParameter("operation:tool_feedRampRel") : getParameter("operation:tool_feedRamp"));
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_RAMP] = feedContext;
      activeMovements[MOVEMENT_RAMP_HELIX] = feedContext;
      activeMovements[MOVEMENT_RAMP_PROFILE] = feedContext;
      activeMovements[MOVEMENT_RAMP_ZIG_ZAG] = feedContext;
    }
    ++id;
  }
  if (hasParameter("operation:tool_feedPlunge")) {
    if (movements & (1 << MOVEMENT_PLUNGE)) {
      var feedContext = new FeedContext(id, localize("Plunge"), feedPerRev ? getParameter("operation:tool_feedPlungeRel") : getParameter("operation:tool_feedPlunge"));
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_PLUNGE] = feedContext;
    }
    ++id;
  }
  if (true) { // high feed
    if (movements & (1 << MOVEMENT_HIGH_FEED)) {
      var feedContext = new FeedContext(id, localize("High Feed"), this.highFeedrate);
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_HIGH_FEED] = feedContext;
    }
    ++id;
  }
  if (hasParameter("operation:tool_feedTransition")) {
    if (movements & (1 << MOVEMENT_LINK_TRANSITION)) {
      var feedContext = new FeedContext(id, localize("Transition"), getParameter("operation:tool_feedTransition"));
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_LINK_TRANSITION] = feedContext;
    }
    ++id;
  }

  for (var i = 0; i < activeFeeds.length; ++i) {
    var feedContext = activeFeeds[i];
    writeBlock("#" + (firstFeedParameter + feedContext.id) + "=" + feedFormat.format(feedContext.feed), formatComment(feedContext.description));
  }
}

var currentWorkPlaneABC = undefined;
var activeDWO = false;

function forceWorkPlane() {
  currentWorkPlaneABC = undefined;
}

function getTCP(abc) {
  tcp = (machineState.axialCenterDrilling || (machineState.usePolarMode || machineState.useXZCMode) ||
          (useG268(abc) && !getProperty("useMultiAxisFeatures")));
  return tcp;
}

// determines if G268 is used
function useG268(abc) {
  if (abc.y != 0) {
    if (!((abcFormat.getResultingValue(abc.y) == 0) || (Math.abs(abcFormat.getResultingValue(abc.y)) == 90))) {
      return true;
    }
  }
  return false;
}

var lengthCompensationActive = false;
function cancelWorkPlane() {
  if (activeDWO || lengthCompensationActive) { // use same code for cancelling DWO and TCP
    writeBlock(gFormat.format(269)); // cancel DWO
    activeDWO = false;
    lengthCompensationActive = false;
  }
}

function setWorkPlane(abc) {
  if (!machineConfiguration.isMultiAxisConfiguration()) {
    return; // ignore
  }

  var _skipBlock = false;
  if (!((currentWorkPlaneABC == undefined) ||
        abcFormat.areDifferent(abc.x, currentWorkPlaneABC.x) ||
        abcFormat.areDifferent(abc.y, currentWorkPlaneABC.y) ||
        abcFormat.areDifferent(abc.z, currentWorkPlaneABC.z))) {
    if (operationNeedsSafeStart) {
      _skipBlock = true;
    } else {
      return; // no change
    }
  }

  skipBlock = _skipBlock;
  cancelWorkPlane();

  if (getProperty("useMultiAxisFeatures") && useG268(abc) &&
      (abcFormat.isSignificant(abc.x) || abcFormat.isSignificant(abc.y) || abcFormat.isSignificant(abc.z))) {
    skipBlock = _skipBlock;
    writeBlock(
      gFormat.format(268),
      "X" + xFormat.format(0), "Y" + yFormat.format(0), "Z" + zFormat.format(0),
      "I" + xFormat.format(toDeg(abc.x)), "J" + yFormat.format(toDeg(abc.y)), "K" + zFormat.format(toDeg(abc.z)),
      "Q123", // EULER_XYZ
      formatComment("ENABLE FCS")
    );
    if (!useABCPrepositioning) {
      writeBlock(gFormat.format(253));  // required to rotate the head
    }
    activeDWO = true;
  }
}

function getBestABCIndex(section) {
  var fitFlag = false;
  var index = undefined;
  for (var i = 0; i < 6; ++i) {
    fitFlag = doesToolpathFitInXYRange(getBestABC(section, i));
    if (fitFlag) {
      index = i;
      break;
    }
  }
  return index;
}

function getBestABC(section, which) {
  var W = section.workPlane;
  var abc = machineConfiguration.getABC(W);
  if (which == undefined) { // turning, XZC, Polar modes
    return abc;
  }
  if (Vector.dot(machineConfiguration.getAxisU().getAxis(), new Vector(0, 0, 1)) != 0) {
    var axis = machineConfiguration.getAxisU(); // C-axis is the U-axis
  } else {
    var axis = machineConfiguration.getAxisV(); // C-axis is the V-axis
  }
  if (axis.isEnabled() && axis.isTable()) {
    var ix = axis.getCoordinate();
    var rotAxis = axis.getAxis();
    if (isSameDirection(machineConfiguration.getDirection(abc), rotAxis) ||
        isSameDirection(machineConfiguration.getDirection(abc), Vector.product(rotAxis, -1))) {
      var direction = isSameDirection(machineConfiguration.getDirection(abc), rotAxis) ? 1 : -1;
      var box = section.getGlobalBoundingBox();
      switch (which) {
      case 1:
        x = box.lower.x + ((box.upper.x - box.lower.x) / 2);
        y = box.lower.y + ((box.upper.y - box.lower.y) / 2);
        break;
      case 2:
        x = box.lower.x;
        y = box.lower.y;
        break;
      case 3:
        x = box.upper.x;
        y = box.lower.y;
        break;
      case 4:
        x = box.upper.x;
        y = box.upper.y;
        break;
      case 5:
        x = box.lower.x;
        y = box.upper.y;
        break;
      default:
        var tempABC = new Vector(0, 0, 0); // don't use B-axis in calculation
        tempABC.setCoordinate(ix, abc.getCoordinate(ix));
        var R = machineConfiguration.getRemainingOrientation(tempABC, W);
        x = R.right.x;
        y = R.right.y;
        break;
      }
      abc.setCoordinate(ix, getCClosest(x, y, cOutput.getCurrent()));
    }
  }
  // writeComment("Which = " + which + "  Angle = " + abc.z)
  return abc;
}

var closestABC = false; // choose closest machine angles
var currentMachineABC = new Vector(0, 0, 0);

function getWorkPlaneMachineABC(section, workPlane) {
  var W = workPlane; // map to global frame

  var abc;
  if (machineState.isTurningOperation && gotBAxis) {
    var both = machineConfiguration.getABCByDirectionBoth(workPlane.forward);
    abc = both[0];
    if (both[0].z != 0) {
      abc = both[1];
    }
  } else {
    abc = getBestABC(section, bestABCIndex);
    if (closestABC) {
      if (currentMachineABC) {
        abc = machineConfiguration.remapToABC(abc, currentMachineABC);
      } else {
        abc = machineConfiguration.getPreferredABC(abc);
      }
    } else {
      abc = machineConfiguration.getPreferredABC(abc);
    }
  }

  try {
    abc = machineConfiguration.remapABC(abc);
  } catch (e) {
    error(
      localize("Machine angles not supported") + ":"
      + conditional(machineConfiguration.isMachineCoordinate(0), " A" + abcFormat.format(abc.x))
      + conditional(machineConfiguration.isMachineCoordinate(1), " B" + abcFormat.format(abc.y))
      + conditional(machineConfiguration.isMachineCoordinate(2), " C" + abcFormat.format(abc.z))
    );
  }

  var direction = machineConfiguration.getDirection(abc);
  if (!isSameDirection(direction, W.forward)) {
    error(localize("Orientation not supported."));
    return abc;
  }

  if (machineState.isTurningOperation && gotBAxis) { // remapABC can change the B-axis orientation
    if (abc.z != 0) {
      error(localize("Could not calculate a B-axis turning angle within the range of the machine."));
      return abc;
    }
  }

  if (!machineConfiguration.isABCSupported(abc)) {
    error(
      localize("Work plane is not supported") + ":"
      + conditional(machineConfiguration.isMachineCoordinate(0), " A" + abcFormat.format(abc.x))
      + conditional(machineConfiguration.isMachineCoordinate(1), " B" + abcFormat.format(abc.y))
      + conditional(machineConfiguration.isMachineCoordinate(2), " C" + abcFormat.format(abc.z))
    );
  }

  if (!machineState.isTurningOperation) {
    var tcp = getTCP(abc);
    if (tcp) {
      var O = machineConfiguration.getOrientation(new Vector(0, 0, abc.z));
      var R = O.getTransposed().multiply(W);
      setRotation(R); // TCP mode
    } else {
      if (true) {
        var O = new Vector(abc.x, isSameDirection(W.forward, new Vector(0, 0, 1)) ? 0 : abc.y, abc.z);
        var R = machineConfiguration.getRemainingOrientation(O, W);
        setRotation(R);
      }
    }
  }

  return abc;
}

function getBAxisOrientationTurning(section) {
  var toolAngle = hasParameter("operation:tool_angle") ? getParameter("operation:tool_angle") : 0;
  var toolOrientation = section.toolOrientation;

  var angle = toRad(toolAngle) + toolOrientation;

  var axis = new Vector(0, 1, 0);
  mappedAngle = (currentSection.spindle == SPINDLE_PRIMARY ? (Math.PI / 2 - angle) : (Math.PI / 2 - angle));
  var mappedAngle;
  if (false) {
    mappedAngle = 0; // manual b-axis used for milling only
  } else {
    mappedAngle = (currentSection.spindle == SPINDLE_PRIMARY ? (Math.PI / 2 - angle) : (Math.PI / 2 - angle));
  }
  var mappedWorkplane = new Matrix(axis, mappedAngle);
  var abc = getWorkPlaneMachineABC(section, mappedWorkplane);
  return abc;
}

function getSpindle(partSpindle) {
  // safety conditions
  if (getNumberOfSections() == 0) {
    return SPINDLE_MAIN;
  }
  if (getCurrentSectionId() < 0) {
    if (machineState.liveToolIsActive && !partSpindle) {
      return SPINDLE_LIVE;
    } else {
      return getSection(getNumberOfSections() - 1).spindle;
    }
  }

  // Turning is active or calling routine requested which spindle part is loaded into
  if (machineState.isTurningOperation || machineState.axialCenterDrilling || partSpindle) {
    return currentSection.spindle;
  //Milling is active
  } else {
    return SPINDLE_LIVE;
  }
}

function prePositionXYZ(initialPosition, abc, lengthOffset, newWorkPlane) {
  var bChanged = (abcFormat.areDifferent(abc.y, currentMachineABC.y));
  var _skipBlock = skipBlock;
  var dwo = !currentSection.isMultiAxis() && getProperty("useMultiAxisFeatures");
  var safeX = toPreciseUnit(getProperty("safeRetractDistanceX"), IN);
  var safeZ = toPreciseUnit(getProperty("safeRetractDistanceZ"), IN);
  if (machineState.isTurningOperation) {
    if (bChanged) {
      if (!retracted[X] && !retracted[Z]) {
        cancelWorkPlane();
        writeRetract(Y, Z);
        writeRetract(X, B);
      }
      var clearance = new Vector(getWorkpiece().upper.x + safeX, 0, getWorkpiece().upper.z + safeZ);
      writeRetractSafeZ(clearance, conditional(machineConfiguration.isMachineCoordinate(1), bOutput.format(getB(abc, currentSection))));
      currentMachineABC = new Vector(abc);
      setCurrentABC(currentMachineABC);
    }
    return;
  }

  gMotionModal.reset();
  if (useABCPrepositioning || !dwo) {
    onCommand(COMMAND_UNLOCK_MULTI_AXIS);
    if (bChanged) {
      forceABC();
      if (!retracted[X] && !retracted[Z]) {
        cancelWorkPlane();
        writeRetract(Y, Z);
        writeRetract(X, B);
      }
      var clearance = new Vector(getWorkpiece().upper.x + safeX, 0, getWorkpiece().upper.z + safeZ);
      writeRetractSafeZ(clearance, conditional(machineConfiguration.isMachineCoordinate(1), bOutput.format(getB(abc, currentSection))));
    }
    skipBlock = _skipBlock;
    writeBlock(
      gMotionModal.format(0),
      conditional(machineConfiguration.isMachineCoordinate(0), aOutput.format(abc.x)),
      conditional(machineConfiguration.isMachineCoordinate(2), cOutput.format(abc.z))
    );
    currentMachineABC = new Vector(abc);
    setCurrentABC(currentMachineABC);
  }

  if (dwo) {
    forceWorkPlane();
    skipBlock = _skipBlock;
    if (useG268(abc)) {
      setWorkPlane(currentSection.workPlane.getEuler2(EULER_XYZ_S));
    } else {
      setWorkPlane(abc);
    }
    forceXYZ();
    skipBlock = _skipBlock;
    /*writeBlock(
      gMotionModal.format(1),
      xOutput.format(dwoClearance.x),
      yOutput.format(dwoClearance.y),
      zOutput.format(dwoClearance.z),
      getFeed(toPreciseUnit(highFeedrate, MM)),
      formatComment("POSITION IN FCS")
    );*/
  }

  if (!currentSection.isMultiAxis() && !machineState.usePolarMode && !machineState.useXZCMode) {
    skipBlock = _skipBlock;
    onCommand(COMMAND_LOCK_MULTI_AXIS);
    currentWorkPlaneABC = abc;
  }
}

var bAxisOrientationTurning = new Vector(0, 0, 0);

function onSection() {
  // Detect machine configuration
  if (gotSecondarySpindle) {
    machineConfiguration = (currentSection.spindle == SPINDLE_PRIMARY) ? machineConfigurationMainSpindle : machineConfigurationSubSpindle;
    if (!gotBAxis) {
      if (getMachiningDirection(currentSection) == MACHINING_DIRECTION_AXIAL && !currentSection.isMultiAxis()) {
        machineConfiguration.setSpindleAxis(new Vector(0, 0, 1));
      } else {
        machineConfiguration.setSpindleAxis(new Vector(1, 0, 0));
      }
    } else {
      machineConfiguration.setSpindleAxis(new Vector(1, 0, 0)); // set the spindle axis depending on B0 orientation
    }
    setMachineConfiguration(machineConfiguration);
    currentSection.optimizeMachineAnglesByMachine(machineConfiguration, OPTIMIZE_AXIS); // map tip mode
  }

  var previousTapping = machineState.tapping;
  machineState.tapping = hasParameter("operation:cycleType") &&
    ((getParameter("operation:cycleType") == "tapping") ||
     (getParameter("operation:cycleType") == "right-tapping") ||
     (getParameter("operation:cycleType") == "left-tapping") ||
     (getParameter("operation:cycleType") == "tapping-with-chip-breaking"));

  var forceToolAndRetract = optionalSection && !currentSection.isOptional();
  optionalSection = currentSection.isOptional();
  bestABCIndex = undefined;

  machineState.isTurningOperation = (currentSection.getType() == TYPE_TURNING);
  if (machineState.isTurningOperation && gotBAxis) {
    bAxisOrientationTurning = getBAxisOrientationTurning(currentSection);
  }
  partCutoff = hasParameter("operation-strategy") && (getParameter("operation-strategy") == "turningPart");
  var insertToolCall = forceToolAndRetract || isFirstSection() ||
    currentSection.getForceToolChange && currentSection.getForceToolChange() ||
    (tool.number != getPreviousSection().getTool().number) ||
    (tool.compensationOffset != getPreviousSection().getTool().compensationOffset) ||
    (tool.diameterOffset != getPreviousSection().getTool().diameterOffset) ||
    (tool.lengthOffset != getPreviousSection().getTool().lengthOffset);
  insertToolCall = (machineState.stockTransferIsActive && partCutoff) ? false : insertToolCall; // tool is loaded during stock transfer op
  var newSpindle = isFirstSection() ||
    (getPreviousSection().spindle != currentSection.spindle);
  var newWorkOffset = isFirstSection() ||
    (getPreviousSection().workOffset != currentSection.workOffset); // work offset changes
  var newWorkPlane = isFirstSection() ||
    !isSameDirection(getPreviousSection().getGlobalFinalToolAxis(), currentSection.getGlobalInitialToolAxis()) ||
    (currentSection.isOptimizedForMachine() && getPreviousSection().isOptimizedForMachine() &&
      Vector.diff(getPreviousSection().getFinalToolAxisABC(), currentSection.getInitialToolAxisABC()).length > 1e-4) ||
    (!machineConfiguration.isMultiAxisConfiguration() && currentSection.isMultiAxis()) ||
    (!getPreviousSection().isMultiAxis() && currentSection.isMultiAxis() ||
      getPreviousSection().isMultiAxis() && !currentSection.isMultiAxis()) ||
    (machineState.isTurningOperation &&
      abcFormat.areDifferent(bAxisOrientationTurning.x, machineState.currentBAxisOrientationTurning.x) ||
      abcFormat.areDifferent(bAxisOrientationTurning.y, machineState.currentBAxisOrientationTurning.y) ||
      abcFormat.areDifferent(bAxisOrientationTurning.z, machineState.currentBAxisOrientationTurning.z));

  operationNeedsSafeStart = getProperty("safeStartAllOperations") && !isFirstSection();

  // define smoothing mode
  initializeSmoothing();

  if ((insertToolCall || newSpindle || newWorkOffset /*|| newWorkPlane*/) &&
      (!machineState.stockTransferIsActive && !partCutoff)) {

    if (insertToolCall) {
      onCommand(COMMAND_COOLANT_OFF);
    }
    cancelWorkPlane();
    writeRetract(Y, Z);
    writeRetract(X, B);
  }

  var yAxisWasEnabled = !machineState.useXZCMode && !machineState.usePolarMode && machineState.liveToolIsActive;
  updateMachiningMode(currentSection); // sets the needed machining mode to machineState (usePolarMode, useXZCMode, axialCenterDrilling)

  if (currentSection.getTool().isLiveTool) {
    if (!isFirstSection() &&
        ((getPreviousSection().getTool().isLiveTool() != currentSection.getTool().isLiveTool()) ||
        (previousTapping && insertToolCall))) {
      writeBlock(getCode("STOP_SPINDLE"));
    }
  } else {
    writeBlock(getCode("STOP_SPINDLE"));
  }

  /*
  if (getProperty("useM97") && !isFirstSection()) {
    writeBlock(mFormat.format(99));
  }
*/

  if (getProperty("useSSV")) {
    // ensure SSV is turned off
    writeBlock(ssvModal.format(39));
  }

  writeln("");

  /*
  if (getProperty("useM97")) {
    writeBlock("N" + spatialFormat.format(currentSection.getId() + getProperty("sequenceNumberStart")));
  }
*/

  // Consider part cutoff as stockTransfer operation
  if (!(machineState.stockTransferIsActive && partCutoff)) {
    machineState.stockTransferIsActive = false;
  }

  if (hasParameter("operation-comment")) {
    var comment = getParameter("operation-comment");
    if (comment) {
      writeComment(comment);
    }
  }

  if (!insertToolCall && operationNeedsSafeStart) {
    skipBlock = true;
    cancelWorkPlane();
    skipBlock = true;
    writeRetract(Y, Z);
    skipBlock = true;
    writeRetract(X, B);
  }

  if (getProperty("showNotes") && hasParameter("notes")) {
    var notes = getParameter("notes");
    if (notes) {
      var lines = String(notes).split("\n");
      var r1 = new RegExp("^[\\s]+", "g");
      var r2 = new RegExp("[\\s]+$", "g");
      for (line in lines) {
        var comment = lines[line].replace(r1, "").replace(r2, "");
        if (comment) {
          writeComment(comment);
        }
      }
    }
  }

  if (insertToolCall || operationNeedsSafeStart) {

    if (getProperty("useM130ToolImages")) {
      writeBlock(mFormat.format(130), "(tool" + tool.number + ".png)");
    }

    if (insertToolCall) {
      forceWorkPlane();
    }

    if (!isFirstSection() && getProperty("optionalStop")) {
      skipBlock = !insertToolCall;
      onCommand(COMMAND_OPTIONAL_STOP);
    }

    /** Handle multiple turrets. */
    if (gotMultiTurret) {
      var activeTurret = tool.turret;
      if (activeTurret == 0) {
        warning(localize("Turret has not been specified. Using Turret 1 as default."));
        activeTurret = 1; // upper turret as default
      }
      switch (activeTurret) {
      case 1:
        // add specific handling for turret 1
        break;
      case 2:
        // add specific handling for turret 2, normally X-axis is reversed for the lower turret
        //xFormat = createFormat({decimals:(unit == MM ? 3 : 4), forceDecimal:true, scale:-1}); // inverted diameter mode
        //xOutput = createVariable({prefix:"X"}, xFormat);
        break;
      default:
        error(localize("Turret is not supported."));
      }
    }

    if (tool.number > 99) {
      warning(localize("Tool number exceeds maximum value."));
    }

    var compensationOffset = tool.isTurningTool() ? tool.compensationOffset : tool.lengthOffset;
    if (compensationOffset > 99) {
      error(localize("Compensation offset is out of range."));
      return;
    }

    if (gotSecondarySpindle) {
      switch (currentSection.spindle) {
      case SPINDLE_PRIMARY: // main spindle
        cFormat = createFormat({decimals:3, forceDecimal:true, scale:DEG});
        cOutput = createVariable({prefix:"C"}, cFormat);
        skipBlock = !insertToolCall;
        writeBlock(gSpindleModal.format(15));
        if (gotYAxis && g100Mirroring) {
          writeBlock(gFormat.format(100), "Y0");
          g100Mirroring = false;
        }
        g14IsActive = false;
        break;
      case SPINDLE_SECONDARY: // sub spindle
        cFormat = createFormat({decimals:3, forceDecimal:true, scale:-DEG});
        cOutput = createVariable({prefix:"M19 R"}, cFormat); // s/b M119 with G15
        skipBlock = !insertToolCall;
        writeBlock(gSpindleModal.format(14));
        if (gotYAxis && !g100Mirroring) {
          writeBlock(gFormat.format(101), "Y0");
          g100Mirroring = true;
        }
        g14IsActive = true;
        break;
      }
    }

    skipBlock = !insertToolCall;
    writeToolBlock("T" + toolFormat.format(tool.number * 100 + compensationOffset), mFormat.format(6));
    if (tool.comment) {
      writeComment(tool.comment);
    }

    var showToolZMin = false;
    if (showToolZMin && (currentSection.getType() == TYPE_MILLING)) {
      if (is3D()) {
        var numberOfSections = getNumberOfSections();
        var zRange = currentSection.getGlobalZRange();
        var number = tool.number;
        for (var i = currentSection.getId() + 1; i < numberOfSections; ++i) {
          var section = getSection(i);
          if (section.getTool().number != number) {
            break;
          }
          zRange.expandToRange(section.getGlobalZRange());
        }
        writeComment(localize("ZMIN") + "=" + zRange.getMinimum());
      }
    }
  }

  if (!machineState.stockTransferIsActive) {
    if (machineState.isTurningOperation || machineState.axialCenterDrilling) {
      machineState.cAxisIsEngaged = false;
    } else { // milling
      machineState.cAxisIsEngaged = true;
    }
  }

  // command stop for manual tool change, useful for quick change live tools
  if ((insertToolCall || operationNeedsSafeStart) && tool.manualToolChange) {
    skipBlock = !insertToolCall;
    onCommand(COMMAND_STOP);
    writeBlock("(" + "MANUAL TOOL CHANGE TO T" + toolFormat.format(tool.number * 100 + compensationOffset) + ")");
  }

  if (newSpindle) {
    // select spindle if required
  }

  gFeedModeModal.reset();
  if ((currentSection.feedMode == FEED_PER_REVOLUTION) || machineState.tapping || machineState.axialCenterDrilling) {
    writeBlock(getCode("FEED_MODE_UNIT_REV")); // unit/rev
  } else {
    writeBlock(getCode("FEED_MODE_UNIT_MIN")); // unit/min
  }

  // Engage tailstock
  if (getProperty("useTailStock")) {
    if (machineState.axialCenterDrilling || (currentSection.spindle == SPINDLE_SECONDARY) ||
       (machineState.liveToolIsActive && (getMachiningDirection(currentSection) == MACHINING_DIRECTION_AXIAL))) {
      if (currentSection.tailstock) {
        warning(localize("Tail stock is not supported for secondary spindle or Z-axis milling."));
      }
      if (machineState.tailstockIsActive) {
        writeBlock(getCode("TAILSTOCK_OFF"));
      }
    } else {
      writeBlock(currentSection.tailstock ? getCode("TAILSTOCK_ON") : getCode("TAILSTOCK_OFF"));
    }
  }

  // see page 138 in 96-8700an for stock transfer / G199/G198
  var spindleChange = tool.type != TOOL_PROBE &&
    (insertToolCall || forceSpindleSpeed || isSpindleSpeedDifferent() || newSpindle ||
    (!machineState.liveToolIsActive && !machineState.mainSpindleIsActive && !machineState.subSpindleIsActive));
  forceSpindleSpeed = false;
  if (operationNeedsSafeStart || spindleChange) {
    if (machineState.isTurningOperation) {
      if (spindleSpeed > 99999) {
        warning(subst(localize("Spindle speed exceeds maximum value for operation \"%1\"."), getOperationComment()));
      }
    } else {
      if (spindleSpeed > 6000) {
        warning(subst(localize("Spindle speed exceeds maximum value for operation \"%1\"."), getOperationComment()));
      }
    }
    skipBlock = !insertToolCall && !spindleChange;
    startSpindle(true, getFramePosition(currentSection.getInitialPosition()));
  }

  previewImage();

  // wcs
  if (insertToolCall) { // force work offset when changing tool
    currentWorkOffset = undefined;
  }
  var workOffset = currentSection.workOffset;
  if (currentSection.workOffset != currentWorkOffset) {
    if (!skipBlock) {
      forceWorkPlane();
    }
    writeBlock(currentSection.wcs);
    currentWorkOffset = currentSection.workOffset;
  }

  // set coolant after we have positioned at Z
  setCoolant(tool.coolant);

  if (currentSection.partCatcher) {
    engagePartCatcher(true);
  }

  forceAny();
  gMotionModal.reset();

  gPlaneModal.reset();
  writeBlock(gPlaneModal.format(getPlane()));

  var abc = new Vector(0, 0, 0);
  cancelTransformation();
  if (machineConfiguration.isMultiAxisConfiguration()) {
    if (machineState.isTurningOperation) {
      if (gotBAxis) {
        bAxisOrientationTurning = getBAxisOrientationTurning(currentSection);
        abc = bAxisOrientationTurning;
        machineState.currentBAxisOrientationTurning = bAxisOrientationTurning;
      } else {
        setRotation(currentSection.workPlane);
      }
    } else {
      if (currentSection.isMultiAxis()) {
        forceWorkPlane();
        onCommand(COMMAND_UNLOCK_MULTI_AXIS);
        abc = currentSection.getInitialToolAxisABC();
      } else {
        if (machineState.useXZCMode) {
          setRotation(currentSection.workPlane); // enables calculation of the C-axis by tool XY-position
          abc = new Vector(0, 0, getCWithinRange(getFramePosition(currentSection.getInitialPosition()).x, getFramePosition(currentSection.getInitialPosition()).y, cOutput.getCurrent()));
        } else {
          abc = getWorkPlaneMachineABC(currentSection, currentSection.workPlane);
        }
      }
      // setWorkPlane(abc);
    }
  } else { // pure 3D
    var remaining = currentSection.workPlane;
    if (!isSameDirection(remaining.forward, new Vector(0, 0, 1))) {
      error(localize("Tool orientation is not supported by the CNC machine."));
      return;
    }
    setRotation(remaining);
  }
  forceAny();

  smoothing.force = operationNeedsSafeStart && (getProperty("useSmoothing") != "-1");
  setSmoothing(smoothing.isAllowed);

  var initialPosition = getFramePosition(currentSection.getInitialPosition());
  if ((machineState.useXZCMode || machineState.usePolarMode) && yAxisWasEnabled) {
    if (gotYAxis && yOutput.isEnabled()) {
      writeBlock(gMotionModal.format(0), yOutput.format(0));
    }
  }
  if (machineState.usePolarMode) {
    setPolarMode(true); // enable polar interpolation mode
  }
  gMotionModal.reset();

  if (insertToolCall || !lengthCompensationActive || newWorkPlane ||
      (!isFirstSection() && (currentSection.isMultiAxis() != getPreviousSection().isMultiAxis()))) {
    var lengthOffset = tool.lengthOffset;
    if ((lengthOffset > 200 && lengthOffset < 1000) || lengthOffset > 9999) {
      error(localize("Length offset out of range."));
      return;
    }
    prePositionXYZ(initialPosition, abc, lengthOffset, newWorkPlane);
  }

  if (getProperty("useG61")) {
    writeBlock(gExactStopModal.format(61));
  }

  if (currentSection.isMultiAxis()) {
    writeBlock(gAbsIncModal.format(390), gFormat.format(234), gMotionModal.format(0), xOutput.format(initialPosition.x), yOutput.format(initialPosition.y), zOutput.format(initialPosition.z));
    lengthCompensationActive = true;
  } else if (insertToolCall || retracted || machineState.useXZCMode || (tool.getSpindleMode() == SPINDLE_CONSTANT_SURFACE_SPEED)) {
    gMotionModal.reset();
    if (machineState.useXZCMode) {
      writeBlock(gMotionModal.format(0), zOutput.format(initialPosition.z));
      writeBlock(
        gMotionModal.format(0),
        xOutput.format(getModulus(initialPosition.x, initialPosition.y)),
        conditional(gotYAxis, yOutput.format(0)),
        cOutput.format(getCWithinRange(initialPosition.x, initialPosition.y, cOutput.getCurrent()))
      );
      setCurrentDirection(new Vector(getCurrentDirection().x, getCurrentDirection().y, cOutput.getCurrent()));
    } else {
      writeBlock(gMotionModal.format(0), gAbsIncModal.format(390), zOutput.format(initialPosition.z));
      writeBlock(gMotionModal.format(0), xOutput.format(initialPosition.x), yOutput.format(initialPosition.y));
    }
  }

  // enable SFM spindle speed
  if (tool.getSpindleMode() == SPINDLE_CONSTANT_SURFACE_SPEED) {
    startSpindle(false);
  }

  if (getProperty("useParametricFeed") &&
      hasParameter("operation-strategy") &&
      (getParameter("operation-strategy") != "drill") && // legacy
      !(currentSection.hasAnyCycle && currentSection.hasAnyCycle()) &&
      !machineState.useXZCMode) {
    if (!insertToolCall &&
        activeMovements &&
        (getCurrentSectionId() > 0) &&
        ((getPreviousSection().getPatternId() == currentSection.getPatternId()) && (currentSection.getPatternId() != 0))) {
      // use the current feeds
    } else {
      initializeActiveFeeds();
    }
  } else {
    activeMovements = undefined;
  }

  if (false) { // DEBUG
    for (var key in machineState) {
      writeComment(key + " : " + machineState[key]);
    }
    // writeComment((getMachineConfigurationAsText(machineConfiguration)));
  }
}

function getPlane() {
  if (getMachiningDirection(currentSection) == MACHINING_DIRECTION_AXIAL) { // axial
    if (machineState.useXZCMode ||
        (currentSection.hasParameter("operation-strategy") && (currentSection.getParameter("operation-strategy") == "drill")) ||
        machineState.isTurningOperation) {
      return 18;
    } else {
      return 17; // G112 and XY milling only
    }
  } else if (getMachiningDirection(currentSection) == MACHINING_DIRECTION_RADIAL) { // radial
    return 19; // YZ plane
  } else if (gotBAxis) {
    return 19; // tilted plane mode
  } else {
    error(subst(localize("Unsupported machining direction for operation " +  "\"" + "%1" + "\"" + "."), getOperationComment()));
    return undefined;
  }
}

/** Returns true if the toolpath fits within the machine XY limits for the given C orientation. */
function doesToolpathFitInXYRange(abc) {
  var xMin = xAxisMinimum * Math.abs(xFormat.getScale());
  var yMin = yAxisMinimum * Math.abs(yFormat.getScale());
  var yMax = yAxisMaximum * Math.abs(yFormat.getScale());
  var c = 0;
  if (abc) {
    c = abc.z;
  }
  if (Vector.dot(machineConfiguration.getAxisU().getAxis(), new Vector(0, 0, 1)) != 0) {
    c *= (machineConfiguration.getAxisU().getAxis().getCoordinate(2) >= 0) ? 1 : -1; // C-axis is the U-axis
  } else {
    c *= (machineConfiguration.getAxisV().getAxis().getCoordinate(2) >= 0) ? 1 : -1; // C-axis is the V-axis
  }

  var dx = new Vector(Math.cos(c), Math.sin(c), 0);
  var dy = new Vector(Math.cos(c + Math.PI / 2), Math.sin(c + Math.PI / 2), 0);

  if (currentSection.getGlobalRange) {
    var xRange = currentSection.getGlobalRange(dx);
    var yRange = currentSection.getGlobalRange(dy);

    if (false) { // DEBUG
      writeComment(
        "toolpath X minimum= " + xFormat.format(xRange[0]) + ", " + "Limit= " + xMin + ", " +
        "within range= " + (xFormat.getResultingValue(xRange[0]) >= xMin)
      );
      writeComment(
        "toolpath Y minimum= " + yFormat.getResultingValue(yRange[0]) + ", " + "Limit= " + yMin + ", " +
        "within range= " + (yFormat.getResultingValue(yRange[0]) >= yMin)
      );
      writeComment(
        "toolpath Y maximum= " + (yFormat.getResultingValue(yRange[1]) + ", " + "Limit= " + yMax) + ", " +
        "within range= " + (yFormat.getResultingValue(yRange[1]) <= yMax)
      );
      writeln("");
    }

    if (getMachiningDirection(currentSection) == MACHINING_DIRECTION_RADIAL) { // G19 plane
      if ((yFormat.getResultingValue(yRange[0]) >= yMin) &&
          (yFormat.getResultingValue(yRange[1]) <= yMax)) {
        return true; // toolpath does fit in XY range
      } else {
        return false; // toolpath does not fit in XY range
      }
    } else { // G17 plane
      if ((xFormat.getResultingValue(xRange[0]) >= xMin) &&
          (yFormat.getResultingValue(yRange[0]) >= yMin) &&
          (yFormat.getResultingValue(yRange[1]) <= yMax)) {
        return true; // toolpath does fit in XY range
      } else {
        return false; // toolpath does not fit in XY range
      }
    }
  } else {
    if (revision < 40000) {
      warning(localize("Please update to the latest release to allow XY linear interpolation instead of polar interpolation."));
    }
    return false; // for older versions without the getGlobalRange() function
  }
}

var MACHINING_DIRECTION_AXIAL = 0;
var MACHINING_DIRECTION_RADIAL = 1;
var MACHINING_DIRECTION_INDEXING = 2;

function getMachiningDirection(section) {
  var forward = section.isMultiAxis() ? section.getGlobalInitialToolAxis() : section.workPlane.forward;
  if (isSameDirection(forward, new Vector(0, 0, 1))) {
    machineState.machiningDirection = MACHINING_DIRECTION_AXIAL;
    return MACHINING_DIRECTION_AXIAL;
  } else if (Vector.dot(forward, new Vector(0, 0, 1)) < 1e-7) {
    machineState.machiningDirection = MACHINING_DIRECTION_RADIAL;
    return MACHINING_DIRECTION_RADIAL;
  } else {
    machineState.machiningDirection = MACHINING_DIRECTION_INDEXING;
    return MACHINING_DIRECTION_INDEXING;
  }
}

function updateMachiningMode(section) {
  machineState.axialCenterDrilling = false; // reset
  machineState.usePolarMode = false; // reset
  machineState.useXZCMode = false; // reset

  if ((section.getType() == TYPE_MILLING) && !section.isMultiAxis()) {
    if (getMachiningDirection(section) == MACHINING_DIRECTION_AXIAL) {
      if (section.hasParameter("operation-strategy") && (section.getParameter("operation-strategy") == "drill")) {
        // drilling axial
        if ((section.getNumberOfCyclePoints() == 1) &&
            !xFormat.isSignificant(getGlobalPosition(section.getInitialPosition()).x) &&
            !yFormat.isSignificant(getGlobalPosition(section.getInitialPosition()).y) &&
            (spatialFormat.format(section.getFinalPosition().x) == 0) &&
            !doesCannedCycleIncludeYAxisMotion(section)) { // catch drill issue for old versions
          // single hole on XY center
          if (section.getTool().isLiveTool && section.getTool().isLiveTool()) {
            if (!gotLiveTooling) {
              warning(localize("Live tools are not supported, using turning spindle instead."));
              machineState.axialCenterDrilling = true;
            }
            // use live tool
          } else {
            // use main spindle for axialCenterDrilling
            machineState.axialCenterDrilling = true;
          }
        } else { // several holes not on XY center
          bestABCIndex = getBestABCIndex(section);
          if (getProperty("useYAxisForDrilling") && (bestABCIndex != undefined) && !doesCannedCycleIncludeYAxisMotion(section)) {
            // use XYZ-mode
          } else { // use XZC mode
            machineState.useXZCMode = true;
          }
        }
      } else { // milling
        bestABCIndex = undefined;
        if (forcePolarMode) { // polar mode is requested by user
          if (currentSection.spindle == SPINDLE_SECONDARY) {
            error(localize("Polar mode G112 is not supported on the secondary spindle."));
          }
          machineState.usePolarMode = true;
        } else if (forceXZCMode) { // XZC mode is requested by user
          machineState.useXZCMode = true;
        } else {
          bestABCIndex = getBestABCIndex(section);
          if (bestABCIndex == undefined) {
            // toolpath does not match XY ranges, enable interpolation mode
            if (getProperty("useG112") && (currentSection.spindle != SPINDLE_SECONDARY)) {
              machineState.usePolarMode = true;
            } else {
              machineState.useXZCMode = true;
            }
          }
        }
      }
    } else if (getMachiningDirection(section) == MACHINING_DIRECTION_RADIAL) { // G19 plane
      if (!gotYAxis) {
        if (!section.isMultiAxis() && (!doesToolpathFitInXYRange(machineConfiguration.getABC(section.workPlane)) || doesCannedCycleIncludeYAxisMotion(section))) {
          error(subst(localize("Y-axis motion is not possible without a Y-axis for operation \"%1\"."), getOperationComment()));
          return;
        }
      } else {
        if (!doesToolpathFitInXYRange(machineConfiguration.getABC(section.workPlane))) {
          error(subst(localize("Toolpath exceeds the maximum ranges for operation \"%1\"."), getOperationComment()));
          return;
        }
      }
      // C-coordinates come from setWorkPlane or is within a multi axis operation, we cannot use the C-axis for non wrapped toolpathes (only multiaxis works, all others have to be into XY range)
    } else {
      // useXZCMode & usePolarMode is only supported for axial machining, keep false
    }
  } else {
    // turning or multi axis, keep false
  }

  if (machineState.axialCenterDrilling) {
    cOutput.disable();
  } else {
    cOutput.enable();
  }

  var checksum = 0;
  checksum += machineState.usePolarMode ? 1 : 0;
  checksum += machineState.useXZCMode ? 1 : 0;
  checksum += machineState.axialCenterDrilling ? 1 : 0;
  validate(checksum <= 1, localize("Internal post processor error."));
  if (!gotLiveTooling && (machineState.usePolarMode || machineState.useXZCMode)) {
    error(localize("Polar G112 or XZC modes are not supported for machines without live tool capabilities."));
    return;
  }
}

function doesCannedCycleIncludeYAxisMotion(section) {
  // these cycles have Y axis motions which are not detected by getGlobalRange()
  var hasYMotion = false;
  if (section.hasParameter("operation:strategy") && (section.getParameter("operation:strategy") == "drill")) {
    switch (section.getParameter("operation:cycleType")) {
    case "thread-milling":
    case "bore-milling":
    case "circular-pocket-milling":
      hasYMotion = true; // toolpath includes Y-axis motion
      break;
    case "back-boring":
    case "fine-boring":
      var orientation = spatialFormat.getResultingValue(section.getParameter("operation:shiftOrientation"));
      var shift = spatialFormat.getResultingValue(section.getParameter("operation:boringShift"));
      if ((orientation != 0 && orientation != 180) && shift != 0) {
        hasYMotion = true; // toolpath includes Y-axis motion
      }
      break;
    default:
      hasYMotion = false; // all other cycles do not have Y-axis motion
    }
  }
  return hasYMotion;
}

function getOperationComment() {
  var operationComment = hasParameter("operation-comment") && getParameter("operation-comment");
  return operationComment;
}

function setPolarMode(activate) {
  if (activate) {
    writeBlock(gMotionModal.format(0), cOutput.format(0)); // set C-axis to 0 to avoid G112 issues
    writeBlock(getCode("POLAR_INTERPOLATION_ON")); // command for polar interpolation
    writeBlock(gPlaneModal.format(getPlane()));
    validate(gPlaneModal.getCurrent() == 17, localize("Internal post processor error.")); // make sure that G17 is active
    xFormat.setScale(1); // radius mode
    xOutput = createVariable({onchange:function() {retracted[X] = false;}, prefix:"X"}, xFormat);
    yOutput.enable(); // required for G112
  } else {
    writeBlock(getCode("POLAR_INTERPOLATION_OFF"));
    xFormat.setScale(2); // diameter mode
    xOutput = createVariable({onchange:function() {retracted[X] = false;}, prefix:"X"}, xFormat);
    if (!gotYAxis) {
      yOutput.disable();
    }
  }
}

function onDwell(seconds) {
  if (seconds > 99999.999) {
    warning(localize("Dwelling time is out of range."));
  }
  milliseconds = clamp(1, seconds * 1000, 99999999);
  writeBlock(gFormat.format(4), "P" + milliFormat.format(milliseconds));
}

var pendingRadiusCompensation = -1;

function onRadiusCompensation() {
  pendingRadiusCompensation = radiusCompensation;
}

var resetFeed = false;

function getHighfeedrate(radius) {
  if (currentSection.feedMode == FEED_PER_REVOLUTION) {
    if (toDeg(radius) <= 0) {
      radius = toPreciseUnit(0.1, MM);
    }
    var rpm = spindleSpeed; // rev/min
    if (currentSection.getTool().getSpindleMode() == SPINDLE_CONSTANT_SURFACE_SPEED) {
      var O = 2 * Math.PI * radius; // in/rev
      rpm = tool.surfaceSpeed / O; // in/min div in/rev => rev/min
    }
    return highFeedrate / rpm; // in/min div rev/min => in/rev
  }
  return highFeedrate;
}

function onRapid(_x, _y, _z) {
  // don't output starts for threading
  if (threadNumber > 0) {
    return;
  }
  if (machineState.useXZCMode) {
    var start = getCurrentPosition();
    var dxy = getModulus(_x - start.x, _y - start.y);
    if (true || (dxy < getTolerance())) {
      var x = xOutput.format(getModulus(_x, _y));
      var c = cOutput.format(getCWithinRange(_x, _y, cOutput.getCurrent()));
      var z = zOutput.format(_z);
      if (pendingRadiusCompensation >= 0) {
        error(localize("Radius compensation mode cannot be changed at rapid traversal."));
        return;
      }
      if (forceRewind) {
        rewindTable(start, _z, cOutput.getCurrent(), highFeedrate, false);
      }
      if (currentSection.spindle == SPINDLE_SECONDARY) {
        writeBlock(gMotionModal.format(0), c);
        writeBlock(gMotionModal.format(0), x, z);
      } else {
        writeBlock(gMotionModal.format(0), x, c, z);
      }
      setCurrentDirection(new Vector(getCurrentDirection().x, getCurrentDirection().y, cOutput.getCurrent()));
      forceFeed();
      return;
    }

    onExpandedLinear(_x, _y, _z, highFeedrate);
    return;
  }

  var x = xOutput.format(_x);
  var y = yOutput.format(_y);
  var z = zOutput.format(_z);
  if (x || y || z) {
    var useG1 = ((x ? 1 : 0) + (y ? 1 : 0) + (z ? 1 : 0)) > 1 && !isCannedCycle;
    if (pendingRadiusCompensation >= 0) {
      pendingRadiusCompensation = -1;

      if (useG1) {
        switch (radiusCompensation) {
        case RADIUS_COMPENSATION_LEFT:
          writeBlock(gMotionModal.format(1), gFormat.format(41), x, y, z, getFeed(getHighfeedrate(_x)));
          break;
        case RADIUS_COMPENSATION_RIGHT:
          writeBlock(gMotionModal.format(1), gFormat.format(42), x, y, z, getFeed(getHighfeedrate(_x)));
          break;
        default:
          writeBlock(gMotionModal.format(1), gFormat.format(40), x, y, z, getFeed(getHighfeedrate(_x)));
        }
      } else {
        switch (radiusCompensation) {
        case RADIUS_COMPENSATION_LEFT:
          writeBlock(gMotionModal.format(0), gFormat.format(41), x, y, z);
          break;
        case RADIUS_COMPENSATION_RIGHT:
          writeBlock(gMotionModal.format(0), gFormat.format(42), x, y, z);
          break;
        default:
          writeBlock(gMotionModal.format(0), gFormat.format(40), x, y, z);
        }
      }
    }
    if (false) {
      // axes are not synchronized
      writeBlock(gMotionModal.format(1), x, y, z, getFeed(getHighfeedrate(_x)));
      resetFeed = false;
    } else {
      writeBlock(gMotionModal.format(0), x, y, z);
      forceFeed();
    }
  }
}

/** Calculate the distance of a point to a line segment. */
function pointLineDistance(startPt, endPt, testPt) {
  var delta = Vector.diff(endPt, startPt);
  distance = Math.abs(delta.y * testPt.x - delta.x * testPt.y + endPt.x * startPt.y - endPt.y * startPt.x) /
    Math.sqrt(delta.y * delta.y + delta.x * delta.x); // distance from line to point
  if (distance < 1e-4) { // make sure point is in line segment
    var moveLength = Vector.diff(endPt, startPt).length;
    var startLength = Vector.diff(startPt, testPt).length;
    var endLength = Vector.diff(endPt, testPt).length;
    if ((startLength > moveLength) || (endLength > moveLength)) {
      distance = Math.min(startLength, endLength);
    }
  }
  return distance;
}

/** Refine segment for XC mapping. */
function refineSegmentXC(startX, startC, endX, endC, maximumDistance) {
  var rotary = machineConfiguration.getAxisU(); // C-axis
  var startPt = rotary.getAxisRotation(startC).multiply(new Vector(startX, 0, 0));
  var endPt = rotary.getAxisRotation(endC).multiply(new Vector(endX, 0, 0));

  var testX = startX + (endX - startX) / 2; // interpolate as the machine
  var testC = startC + (endC - startC) / 2;
  var testPt = rotary.getAxisRotation(testC).multiply(new Vector(testX, 0, 0));

  var delta = Vector.diff(endPt, startPt);
  var distf = pointLineDistance(startPt, endPt, testPt);

  if (distf > maximumDistance) {
    return false; // out of tolerance
  } else {
    return true;
  }
}

function rewindTable(startXYZ, currentZ, rewindC, feed, retract) {
  if (!cFormat.areDifferent(rewindC, cOutput.getCurrent())) {
    error(localize("Rewind position not found."));
    return;
  }
  writeComment("Rewind of C-axis, make sure retracting is possible.");
  onCommand(COMMAND_STOP);
  if (retract) {
    writeBlock(gMotionModal.format(1), zOutput.format(currentSection.getInitialPosition().z), getFeed(feed));
  }
  writeBlock(getCode("DISENGAGE_C_AXIS"));
  writeBlock(getCode("ENGAGE_C_AXIS"));
  gMotionModal.reset();
  xOutput.reset();
  startSpindle(false);
  if (retract) {
    var x = getModulus(startXYZ.x, startXYZ.y);
    if (true) {
      writeBlock(gMotionModal.format(1), xOutput.format(x), getFeed(highFeedrate));
      writeBlock(gMotionModal.format(0), cOutput.format(rewindC));
    } else {
      writeBlock(gMotionModal.format(1), xOutput.format(x), cOutput.format(rewindC), getFeed(highFeedrate));
    }
    writeBlock(gMotionModal.format(1), zOutput.format(startXYZ.z), getFeed(feed));
  }
  setCoolant(tool.coolant);
  forceRewind = false;
  writeComment("End of rewind");
}

function getMultiaxisFeed(x, y, z, a, b, c, feed) {
  var length = getMultiAxisMoveLength(x, y, z, a, b, c);
  var time = length.getRadialToolTipMoveLength() / feed;
  var frn = Math.min(time == 0 ? multiAxisFeedrate.maximum : 1 / time, multiAxisFeedrate.maximum);
  return {fMode:93, frn:frn};
}

function onLinear(_x, _y, _z, feed) {
  // don't output starts for threading
  if (threadNumber > 0) {
    return;
  }
  if (machineState.useXZCMode) {
    if (currentSection.spindle == SPINDLE_SECONDARY) {
      if ((hasParameter("operation:strategy") && (getParameter("operation:strategy") == "drill") && !doesCannedCycleIncludeYAxisMotion(currentSection))) {
        // allow drilling in XZC-mode
      } else {
        error(localize("XZC-mode is not supported on the secondary spindle."));
      }
    }
    if (pendingRadiusCompensation >= 0) {
      error(subst(localize("Radius compensation is not supported for operation \"%1\". " + EOL +
      "You must either enable the property 'Use G112 polar interpolation' or use a Manual NC Action with keyword 'usepolarmode' to be able to use radius compensation."), getOperationComment()));
      return;
    }
    if (maximumCircularSweep > toRad(179)) {
      error(localize("Maximum circular sweep must be below 179 degrees."));
      return;
    }

    var localTolerance = getTolerance() / 4;

    var startXYZ = getCurrentPosition();
    var startX = getModulus(startXYZ.x, startXYZ.y);
    var startZ = startXYZ.z;
    var startC = cOutput.getCurrent();

    var endXYZ = new Vector(_x, _y, _z);
    var endX = getModulus(endXYZ.x, endXYZ.y);
    var endZ = endXYZ.z;
    var endC = getCWithinRange(endXYZ.x, endXYZ.y, startC);

    var currentXYZ = endXYZ; var currentX = endX; var currentZ = endZ; var currentC = endC;
    var centerXYZ = machineConfiguration.getAxisU().getOffset();

    var refined = true;
    var crossingRotary = false;
    forceOptimized = false; // tool tip is provided to DPM calculations
    while (refined) { // stop if we dont refine
      // check if we cross center of rotary axis
      var _start = new Vector(startXYZ.x, startXYZ.y, 0);
      var _current = new Vector(currentXYZ.x, currentXYZ.y, 0);
      var _center = new Vector(centerXYZ.x, centerXYZ.y, 0);
      if ((xFormat.getResultingValue(pointLineDistance(_start, _current, _center)) == 0) &&
          (xFormat.getResultingValue(Vector.diff(_start, _center).length) != 0) &&
          (xFormat.getResultingValue(Vector.diff(_current, _center).length) != 0)) {
        var ratio = Vector.diff(_center, _start).length / Vector.diff(_current, _start).length;
        currentXYZ = centerXYZ;
        currentXYZ.z = startZ + (endZ - startZ) * ratio;
        currentX = getModulus(currentXYZ.x, currentXYZ.y);
        currentZ = currentXYZ.z;
        currentC = startC;
        crossingRotary = true;
      } else { // check if move is out of tolerance
        refined = false;
        while (!refineSegmentXC(startX, startC, currentX, currentC, localTolerance)) { // move is out of tolerance
          refined = true;
          currentXYZ = Vector.lerp(startXYZ, currentXYZ, 0.75);
          currentX = getModulus(currentXYZ.x, currentXYZ.y);
          currentZ = currentXYZ.z;
          currentC = getCWithinRange(currentXYZ.x, currentXYZ.y, startC);
          if (Vector.diff(startXYZ, currentXYZ).length < 1e-5) { // back to start point, output error
            if (forceRewind) {
              break;
            } else {
              warning(localize("Linear move cannot be mapped to rotary XZC motion."));
              break;
            }
          }
        }
      }

      currentC = getCWithinRange(currentXYZ.x, currentXYZ.y, startC);
      if (forceRewind) {
        var rewindC = getCClosest(startXYZ.x, startXYZ.y, currentC);
        xOutput.reset(); // force X for repositioning
        rewindTable(startXYZ, currentZ, rewindC, feed, true);
        setCurrentDirection(new Vector(getCurrentDirection().x, getCurrentDirection().y, rewindC));
      }
      var x = xOutput.format(currentX);
      var c = cOutput.format(currentC);
      var z = zOutput.format(currentZ);
      var actualFeed = getMultiaxisFeed(currentXYZ.x, currentXYZ.y, currentXYZ.z, 0, 0, currentC, feed);
      if (x || c || z) {
        writeBlock(gFeedModeModal.format(actualFeed.fMode), gMotionModal.format(1), x, c, z, inverseTimeOutput.format(actualFeed.frn));
      }
      setCurrentPosition(currentXYZ);
      setCurrentDirection(new Vector(getCurrentDirection().x, getCurrentDirection().y, currentC));
      if (crossingRotary) {
        writeBlock(gMotionModal.format(1), cOutput.format(endC), getFeed(feed)); // rotate at X0 with endC
        setCurrentDirection(new Vector(getCurrentDirection().x, getCurrentDirection().y, endC));
        forceFeed();
      }
      startX = currentX; startZ = currentZ; startC = crossingRotary ? endC : currentC; startXYZ = currentXYZ; // loop start point
      currentX = endX; currentZ = endZ; currentC = endC; currentXYZ = endXYZ; // loop end point
      crossingRotary = false;
    }
    forceOptimized = undefined;
    return;
  }

  if (isSpeedFeedSynchronizationActive()) {
    resetFeed = true;
    var threadPitch = getParameter("operation:threadPitch");
    var threadsPerInch = 1.0 / threadPitch; // per mm for metric
    writeBlock(gMotionModal.format(32), xOutput.format(_x), yOutput.format(_y), zOutput.format(_z), pitchOutput.format(1 / threadsPerInch));
    return;
  }
  if (resetFeed) {
    resetFeed = false;
    forceFeed();
  }
  var x = xOutput.format(_x);
  var y = yOutput.format(_y);
  var z = zOutput.format(_z);
  var f = ((currentSection.feedMode != FEED_PER_REVOLUTION) && machineState.feedPerRevolution) ? feedOutput.format(feed / spindleSpeed) : getFeed(feed);
  if (x || y || z) {
    if (pendingRadiusCompensation >= 0) {
      pendingRadiusCompensation = -1;
      writeBlock(gPlaneModal.format(getPlane()));
      if (getMachiningDirection(currentSection) == MACHINING_DIRECTION_INDEXING) {
        error(localize("Tool orientation is not supported for radius compensation."));
        return;
      }
      switch (radiusCompensation) {
      case RADIUS_COMPENSATION_LEFT:
        writeBlock(gMotionModal.format(isSpeedFeedSynchronizationActive() ? 32 : 1), gFormat.format(41), x, y, z, f);
        break;
      case RADIUS_COMPENSATION_RIGHT:
        writeBlock(gMotionModal.format(isSpeedFeedSynchronizationActive() ? 32 : 1), gFormat.format(42), x, y, z, f);
        break;
      default:
        writeBlock(gMotionModal.format(isSpeedFeedSynchronizationActive() ? 32 : 1), gFormat.format(40), x, y, z, f);
      }
    } else {
      writeBlock(gMotionModal.format(isSpeedFeedSynchronizationActive() ? 32 : 1), x, y, z, f);
    }
  } else if (f) {
    if (getNextRecord().isMotion()) { // try not to output feed without motion
      forceFeed(); // force feed on next line
    } else {
      writeBlock(gMotionModal.format(isSpeedFeedSynchronizationActive() ? 32 : 1), f);
    }
  }
}

function onRapid5D(_x, _y, _z, _a, _b, _c) {
  if (!currentSection.isOptimizedForMachine()) {
    error(localize("Multi-axis motion is not supported for XZC mode."));
    return;
  }
  if (currentSection.spindle == SPINDLE_SECONDARY) {
    error(localize("Multi-axis motion is not supported on the secondary spindle."));
  }
  if (pendingRadiusCompensation >= 0) {
    error(localize("Radius compensation mode cannot be changed at rapid traversal."));
    return;
  }
  var x = xOutput.format(_x);
  var y = yOutput.format(_y);
  var z = zOutput.format(_z);
  var a = aOutput.format(_a);
  var b = bOutput.format(getB(new Vector(_a, _b, _c), currentSection));
  var c = cOutput.format(_c);
  if (true) {
    // axes are not synchronized
    writeBlock(gMotionModal.format(1), x, y, z, a, b, c, getFeed(highFeedrate));
  } else {
    writeBlock(gMotionModal.format(0), x, y, z, a, b, c);
    forceFeed();
  }
}

function onLinear5D(_x, _y, _z, _a, _b, _c, feed, feedMode) {
  if (!currentSection.isOptimizedForMachine()) {
    error(localize("Multi-axis motion is not supported for XZC mode."));
    return;
  }
  if (currentSection.spindle == SPINDLE_SECONDARY) {
    error(localize("Multi-axis motion is not supported on the secondary spindle."));
  }
  if (pendingRadiusCompensation >= 0) {
    error(localize("Radius compensation cannot be activated/deactivated for 5-axis move."));
    return;
  }
  var x = xOutput.format(_x);
  var y = yOutput.format(_y);
  var z = zOutput.format(_z);
  var a = aOutput.format(_a);
  var b = bOutput.format(getB(new Vector(_a, _b, _c), currentSection));
  var c = cOutput.format(_c);

  // get feedrate number
  if (feedMode == FEED_INVERSE_TIME) {
    feedOutput.reset();
  }
  var fMode = feedMode == FEED_INVERSE_TIME ? 93 : 98;
  var f = feedMode == FEED_INVERSE_TIME ? inverseTimeOutput.format(feed) : feedOutput.format(feed);

  if (x || y || z || a || b || c) {
    writeBlock(gFeedModeModal.format(fMode), gMotionModal.format(1), x, y, z, a, b, c, f);
  } else if (f) {
    if (getNextRecord().isMotion()) { // try not to output feed without motion
      forceFeed(); // force feed on next line
    } else {
      writeBlock(gFeedModeModal.format(fMode), gMotionModal.format(1), f);
    }
  }
}

// Start of onRewindMachine logic
/** Allow user to override the onRewind logic. */
function onRewindMachineEntry(_a, _b, _c) {
  return false;
}

/** Retract to safe position before indexing rotaries. */
function onMoveToSafeRetractPosition() {
  var workpiece = getWorkpiece();
  var clearance = workpiece.upper.z + getProperty("safeRetractDistanceZ");
  writeRetractSafeZ(clearance, getCurrentDirection().z);
}

/** Rotate axes to new position above reentry position */
function onRotateAxes(_x, _y, _z, _a, _b, _c) {
  // position rotary axes
  xOutput.disable();
  yOutput.disable();
  zOutput.disable();
  forceG0 = true;
  invokeOnRapid5D(_x, _y, _z, _a, _b, _c);
  setCurrentABC(new Vector(_a, _b, _c));
  xOutput.enable();
  yOutput.enable();
  zOutput.enable();
}

/** Return from safe position after indexing rotaries. */
function onReturnFromSafeRetractPosition(_x, _y, _z) {
  onExpandedRapid(_x, _y, _z);
}
// End of onRewindMachine logic

function onCircular(clockwise, cx, cy, cz, x, y, z, feed) {
  if (activeDWO && getCircularPlane() != PLANE_XY) {
    linearize(tolerance);
    return;
  }

  var directionCode = clockwise ? 2 : 3;
  var toler = (machineState.useXZCMode || machineState.usePolarMode) ? getTolerance() / 2 : getTolerance();
  if (machineState.useXZCMode) {
    switch (getCircularPlane()) {
    case PLANE_ZX:
      if (!isSpiral()) {
        var c = getCClosest(x, y, cOutput.getCurrent());
        if (!cFormat.areDifferent(c, cOutput.getCurrent())) {
          validate(getCircularSweep() < Math.PI, localize("Circular sweep exceeds limit."));
          var start = getCurrentPosition();
          writeBlock(gPlaneModal.format(18), gMotionModal.format(clockwise ? 2 : 3), xOutput.format(getModulus(x, y)), cOutput.format(c), zOutput.format(z), iOutput.format(cx - start.x, 0), kOutput.format(cz - start.z, 0), getFeed(feed));
          setCurrentDirection(new Vector(getCurrentDirection().x, getCurrentDirection().y, c));
          return;
        }
      }
      break;
    case PLANE_XY:
      var d2 = center.x * center.x + center.y * center.y;
      if (d2 < 1e-6) { // center is on rotary axis
        var c = getCWithinRange(x, y, cOutput.getCurrent(), !clockwise);
        if (!forceRewind) {
          var actualFeed = getMultiaxisFeed(x, y, z, 0, 0, c, feed);
          writeBlock(gFeedModeModal.format(actualFeed.fMode), gMotionModal.format(1), xOutput.format(getModulus(x, y)), cOutput.format(c), zOutput.format(z), inverseTimeOutput.format(actualFeed.frn));
          setCurrentDirection(new Vector(getCurrentDirection().x, getCurrentDirection().y, c));
          return;
        }
      }
      break;
    }

    linearize(toler);
    return;
  }

  if (machineState.usePolarMode && !getProperty("usePolarCircular")) {
    linearize(toler);
    return;
  }

  if (isSpeedFeedSynchronizationActive()) {
    error(localize("Speed-feed synchronization is not supported for circular moves."));
    return;
  }

  if (pendingRadiusCompensation >= 0) {
    error(localize("Radius compensation cannot be activated/deactivated for a circular move."));
    return;
  }

  var start = getCurrentPosition();

  if (isFullCircle()) {
    if (getProperty("useRadius") || isHelical()) { // radius mode does not support full arcs
      linearize(toler);
      return;
    }
    switch (getCircularPlane()) {
    case PLANE_XY:
      writeBlock(gPlaneModal.format(activeDWO ? getPlane() : 17), gMotionModal.format(directionCode), iOutput.format(cx - start.x, 0), jOutput.format(cy - start.y, 0), getFeed(feed));
      break;
    case PLANE_ZX:
      if (machineState.usePolarMode) {
        linearize(tolerance);
        return;
      }
      writeBlock(gPlaneModal.format(18), gMotionModal.format(clockwise ? 2 : 3), iOutput.format(cx - start.x, 0), kOutput.format(cz - start.z, 0), getFeed(feed));
      break;
    case PLANE_YZ:
      if (machineState.usePolarMode) {
        linearize(tolerance);
        return;
      }
      writeBlock(gPlaneModal.format(19), gMotionModal.format(directionCode), jOutput.format(cy - start.y, 0), kOutput.format(cz - start.z, 0), getFeed(feed));
      break;
    default:
      linearize(toler);
    }
  } else if (!getProperty("useRadius")) {
    if (isHelical() && ((getCircularSweep() < toRad(30)) || (getHelicalPitch() > 10))) { // avoid G112 issue
      linearize(toler);
      return;
    }
    switch (getCircularPlane()) {
    case PLANE_XY:
      if (!xFormat.isSignificant(start.x) && machineState.usePolarMode) {
        linearize(toler); // avoid G112 issues
        return;
      }
      writeBlock(gPlaneModal.format(activeDWO ? getPlane() : 17), gMotionModal.format(directionCode), xOutput.format(x), yOutput.format(y), zOutput.format(z), iOutput.format(cx - start.x, 0), jOutput.format(cy - start.y, 0), getFeed(feed));
      break;
    case PLANE_ZX:
      if (machineState.usePolarMode) {
        linearize(tolerance);
        return;
      }
      writeBlock(gPlaneModal.format(18), gMotionModal.format(clockwise ? 2 : 3), xOutput.format(x), yOutput.format(y), zOutput.format(z), iOutput.format(cx - start.x, 0), kOutput.format(cz - start.z, 0), getFeed(feed));
      break;
    case PLANE_YZ:
      if (machineState.usePolarMode) {
        linearize(tolerance);
        return;
      }
      writeBlock(gPlaneModal.format(19), gMotionModal.format(directionCode), xOutput.format(x), yOutput.format(y), zOutput.format(z), jOutput.format(cy - start.y, 0), kOutput.format(cz - start.z, 0), getFeed(feed));
      break;
    default:
      linearize(toler);
    }
  } else { // use radius mode
    if (isHelical() && ((getCircularSweep() < toRad(30)) || (getHelicalPitch() > 10))) {
      linearize(toler);
      return;
    }
    var r = getCircularRadius();
    if (toDeg(getCircularSweep()) > (180 + 1e-9)) {
      r = -r; // allow up to <360 deg arcs
    }
    switch (getCircularPlane()) {
    case PLANE_XY:
      if (!xFormat.isSignificant(start.x) && machineState.usePolarMode) {
        linearize(toler); // avoid G112 issues
        return;
      }
      writeBlock(gPlaneModal.format(activeDWO ? getPlane() : 17), gMotionModal.format(directionCode), xOutput.format(x), yOutput.format(y), zOutput.format(z), "R" + rFormat.format(r), getFeed(feed));
      break;
    case PLANE_ZX:
      if (machineState.usePolarMode) {
        linearize(tolerance);
        return;
      }
      writeBlock(gPlaneModal.format(18), gMotionModal.format(clockwise ? 2 : 3), xOutput.format(x), yOutput.format(y), zOutput.format(z), "R" + rFormat.format(r), getFeed(feed));
      break;
    case PLANE_YZ:
      if (machineState.usePolarMode) {
        linearize(tolerance);
        return;
      }
      writeBlock(gPlaneModal.format(19), gMotionModal.format(directionCode), xOutput.format(x), yOutput.format(y), zOutput.format(z), "R" + rFormat.format(r), getFeed(feed));
      break;
    default:
      linearize(toler);
    }
  }
}

function onCycle() {
  if ((typeof isSubSpindleCycle == "function") && isSubSpindleCycle(cycleType)) {
    if (!gotSecondarySpindle) {
      error(localize("Secondary spindle is not available."));
      return;
    }
    error(localize("Stock transfer is not customized for your machine"));
    return;
  }
}

var saveShowSequenceNumbers;
var pathBlockNumber = {start:0, end:0};
var isCannedCycle = false;

function onCyclePath() {
  saveShowSequenceNumbers = getProperty("showSequenceNumbers");
  isCannedCycle = true;
  // buffer all paths and stop feeds being output
  feedOutput.disable();
  setProperty("showSequenceNumbers", "false");
  redirectToBuffer();
  gMotionModal.reset();
  if ((hasParameter("operation:grooving") && getParameter("operation:grooving").toUpperCase() != "OFF")) {
    xOutput.reset();
    zOutput.reset();
  }
}

function onCyclePathEnd() {
  setProperty("showSequenceNumbers", saveShowSequenceNumbers); // reset property to initial state
  feedOutput.enable();
  var cyclePath = String(getRedirectionBuffer()).split(EOL); // get cycle path from buffer
  closeRedirection();
  for (line in cyclePath) { // remove empty elements
    if (cyclePath[line] == "") {
      cyclePath.splice(line);
    }
  }

  var verticalPasses;
  if (cycle.profileRoughingCycle == 0) {
    verticalPasses = false;
  } else if (cycle.profileRoughingCycle == 1) {
    verticalPasses = true;
  } else {
    error(localize("Unsupported passes type."));
    return;
  }
  // output cycle data
  switch (cycleType) {
  case "turning-canned-rough":
    writeBlock(gFormat.format(verticalPasses ? 72 : 71),
      "P" + (getStartEndSequenceNumber(cyclePath, true)),
      "Q" + (getStartEndSequenceNumber(cyclePath, false)),
      "U" + xFormat.format(cycle.xStockToLeave),
      "W" + spatialFormat.format(cycle.zStockToLeave),
      "D" + spatialFormat.format(cycle.depthOfCut),
      getFeed(cycle.cutfeedrate)
    );
    break;
  default:
    error(localize("Unsupported turning canned cycle."));
  }

  for (var i = 0; i < cyclePath.length; ++i) {
    if (i == 0 || i == (cyclePath.length - 1)) { // write sequence number on first and last line of the cycle path
      setProperty("showSequenceNumbers", "true");
      if ((i == 0 && pathBlockNumber.start != sequenceNumber) || (i == (cyclePath.length - 1) && pathBlockNumber.end != sequenceNumber)) {
        error(localize("Mismatch of start/end block number in turning canned cycle."));
        return;
      }
    }
    writeBlock(cyclePath[i]); // output cycle path
    setProperty("showSequenceNumbers", saveShowSequenceNumbers); // reset property to initial state
    isCannedCycle = false;
  }
}

function getStartEndSequenceNumber(cyclePath, start) {
  if (start) {
    pathBlockNumber.start = sequenceNumber + conditional(saveShowSequenceNumbers == "true", getProperty("sequenceNumberIncrement"));
    return pathBlockNumber.start;
  } else {
    pathBlockNumber.end = sequenceNumber + getProperty("sequenceNumberIncrement") + conditional(saveShowSequenceNumbers == "true", (cyclePath.length - 1) * getProperty("sequenceNumberIncrement"));
    return pathBlockNumber.end;
  }
}

function getCommonCycle(x, y, z, r) {
  // forceXYZ(); // force xyz on first drill hole of any cycle
  if (machineState.useXZCMode) {
    cOutput.reset();
    if (currentSection.spindle == SPINDLE_SECONDARY) {
      onCommand(COMMAND_UNLOCK_MULTI_AXIS);
      writeBlock(cOutput.format(getCWithinRange(x, y, cOutput.getCurrent())));
      onCommand(COMMAND_LOCK_MULTI_AXIS);
      return [xOutput.format(getModulus(x, y)), zOutput.format(z),
        (r !== undefined) ? ("R" + spatialFormat.format(r)) : ""];
    } else {
      return [xOutput.format(getModulus(x, y)), cOutput.format(getCWithinRange(x, y, cOutput.getCurrent())),
        zOutput.format(z),
        (r !== undefined) ? ("R" + spatialFormat.format((gPlaneModal.getCurrent() == 19) ? r * xFormat.getScale() : r)) : ""];
    }
  } else {
    return [xOutput.format(x), yOutput.format(y),
      zOutput.format(z),
      (r !== undefined) ? ("R" + spatialFormat.format((gPlaneModal.getCurrent() == 19) ? r * xFormat.getScale() : r)) : ""];
  }
}

function writeCycleClearance() {
  if (true) {
    var z;
    switch (gPlaneModal.getCurrent()) {
    case 17:
      z = zOutput.format(cycle.clearance);
      break;
    case 18:
      z = zOutput.format(cycle.clearance);
      break;
    case 19:
      z = xOutput.format(cycle.clearance);
      break;
    default:
      error(localize("Unsupported drilling orientation."));
      return;
    }
    if (z) {
      onCycleEnd();
      writeBlock(gMotionModal.format(0), z);
    }
  }
}

var threadNumber = 0;
var numberOfThreads = 1;
function onCyclePoint(x, y, z) {

  if (!getProperty("useCycles") || currentSection.isMultiAxis() ||
      (getMachiningDirection(currentSection) == MACHINING_DIRECTION_INDEXING && !activeDWO)) {
    expandCyclePoint(x, y, z);
    return;
  }
  writeBlock(gPlaneModal.format(getPlane()));

  var gCycleTapping;
  switch (cycleType) {
  case "tapping-with-chip-breaking":
  case "right-tapping":
  case "left-tapping":
  case "tapping":
    if (gPlaneModal.getCurrent() == 19) { // radial
      if (tool.type == TOOL_TAP_LEFT_HAND) {
        gCycleTapping = 196;
      } else {
        gCycleTapping = 195;
      }
    } else { // axial
      if (tool.type == TOOL_TAP_LEFT_HAND) {
        gCycleTapping = machineState.axialCenterDrilling ? 184 : 186;
      } else {
        gCycleTapping = machineState.axialCenterDrilling ? 84 : 95;
      }
    }
    break;
  }

  switch (cycleType) {
  case "thread-turning":
    // find number of threads and count which thread we are on
    numberOfThreads = 1;
    if ((hasParameter("operation:doMultipleThreads") && (getParameter("operation:doMultipleThreads") != 0))) {
      numberOfThreads = getParameter("operation:numberOfThreads");
    }
    if (isFirstCyclePoint()) {
      // increment thread number for multiple threads
      threadNumber += 1;
    }

    var threadPhaseAngle = (360 / numberOfThreads) * (threadNumber - 1);

    if (getProperty("useSimpleThread")) {
      var i = -cycle.incrementalX; // positive if taper goes down - delta radius

      // move to thread start for infeed angle other than 0, multiple threads and alternate infeed.
      if (zFormat.areDifferent(zOutput.getCurrent(), zFormat.getResultingValue(z))) {
        var zOut = zOutput.format(z - cycle.incrementalZ);
        if (zOut) {
          writeBlock(gMotionModal.format(0), zOut);
        }
        g92IOutput.reset();
        g92QOutput.reset();
        gCycleModal.reset();
        forceFeed();
        xOutput.reset();
        zOutput.reset();
      }

      writeBlock(
        gCycleModal.format(92),
        xOutput.format(x - cycle.incrementalX),
        yOutput.format(y),
        zOutput.format(z),
        conditional(zFormat.isSignificant(i), g92IOutput.format(i)),
        conditional(numberOfThreads > 1, g92QOutput.format(threadPhaseAngle)),
        feedOutput.format(cycle.pitch)
      );
    } else {
      if (isLastCyclePoint()) {
        // thread height and depth of cut
        var threadHeight = getParameter("operation:threadDepth");
        var firstDepthOfCut = threadHeight - Math.abs(getCyclePoint(0).x - x);
        var cuttingAngle = getParameter("operation:infeedAngle", 29.5) * 2; // Angle is not stored with tool. toDeg(tool.getTaperAngle());
        var i = -cycle.incrementalX; // positive if taper goes down - delta radius
        gCycleModal.reset();

        var threadInfeedMode = "constant";
        if (hasParameter("operation:infeedMode")) {
          threadInfeedMode = getParameter("operation:infeedMode");
        }

        //  Cutting Method:
        //  P1 = Constant Amount/1 Edge
        //  P2 = Constant Amount/Both Edges
        //  P3 = Constant Depth/One Edge
        //  P4 = Constant Depth/Both Edges >>>>>> not supported

        var threadCuttingMode = 3;
        if (threadInfeedMode == "reduced") {
          threadCuttingMode = 1;
        } else if (threadInfeedMode == "constant") {
          threadCuttingMode = 3;
        } else if (threadInfeedMode == "alternate") {
          threadCuttingMode = 2;
        } else {
          error(localize("Unsupported Infeed Mode."));
          return;
        }

        // threading cycle
        gCycleModal.reset();
        xOutput.reset();
        zOutput.reset();
        writeBlock(
          gCycleModal.format(76),
          xOutput.format(x - cycle.incrementalX),
          zOutput.format(z),
          conditional(zFormat.isSignificant(i), g76IOutput.format(i)),
          g76KOutput.format(threadHeight),
          g76DOutput.format(firstDepthOfCut),
          g76AOutput.format(cuttingAngle),
          "P" + integerFormat.format(threadCuttingMode),
          conditional(numberOfThreads > 1, g76QOutput.format(threadPhaseAngle)),
          pitchOutput.format(cycle.pitch)
        );
      }
    }
    gMotionModal.reset();
    return;
  }
  if (true) {
    if (gPlaneModal.getCurrent() == 17) {
      error(localize("Drilling in G17 is not supported."));
      return;
    }
    // repositionToCycleClearance(cycle, x, y, z);
    // return to initial Z which is clearance plane and set absolute mode
    feedOutput.reset();

    var F = (machineState.feedPerRevolution ? cycle.feedrate / spindleSpeed : cycle.feedrate);
    var P = (cycle.dwell == 0) ? 0 : clamp(1, cycle.dwell * 1000, 99999999); // in milliseconds

    switch (cycleType) {
    case "drilling":
      forceXYZ();
      writeCycleClearance();
      writeBlock(
        gCycleModal.format(gPlaneModal.getCurrent() == 19 ? 241 : 81),
        getCommonCycle(x, y, z, cycle.retract),
        feedOutput.format(F)
      );
      break;
    case "counter-boring":
      writeCycleClearance();
      forceXYZ();
      if (P > 0) {
        writeBlock(
          gCycleModal.format(gPlaneModal.getCurrent() == 19 ? 242 : 82),
          getCommonCycle(x, y, z, cycle.retract),
          "P" + milliFormat.format(P),
          feedOutput.format(F)
        );
      } else {
        writeBlock(
          gCycleModal.format(gPlaneModal.getCurrent() == 19 ? 241 : 81),
          getCommonCycle(x, y, z, cycle.retract),
          feedOutput.format(F)
        );
      }
      break;
    case "chip-breaking":
    case "deep-drilling":
      if (cycleType == "chip-breaking" && (cycle.accumulatedDepth < cycle.depth)) {
        expandCyclePoint(x, y, z);
        return;
      } else {
        writeCycleClearance();
        forceXYZ();
        writeBlock(
          gCycleModal.format(gPlaneModal.getCurrent() == 19 ? 243 : 83),
          getCommonCycle(x, y, z, cycle.retract),
          "Q" + spatialFormat.format(cycle.incrementalDepth), // lathe prefers single Q peck value, IJK causes error
          // "I" + spatialFormat.format(cycle.incrementalDepth),
          // "J" + spatialFormat.format(cycle.incrementalDepthReduction),
          // "K" + spatialFormat.format(cycle.minimumIncrementalDepth),
          conditional(P > 0, "P" + milliFormat.format(P)),
          feedOutput.format(F)
        );
      }
      break;
    case "tapping":
      writeCycleClearance();
      if (gPlaneModal.getCurrent() == 19) {
        xOutput.reset();
        writeBlock(gMotionModal.format(0), zOutput.format(z), yOutput.format(y));
        writeBlock(gMotionModal.format(0), xOutput.format(cycle.retract));
        writeBlock(
          gCycleModal.format(gCycleTapping),
          getCommonCycle(x, y, z, undefined),
          pitchOutput.format(F)
        );
      } else {
        forceXYZ();
        writeBlock(
          gCycleModal.format(gCycleTapping),
          getCommonCycle(x, y, z, cycle.retract),
          pitchOutput.format(F)
        );
      }
      forceFeed();
      break;
    case "left-tapping":
      writeCycleClearance();
      xOutput.reset();
      if (gPlaneModal.getCurrent() == 19) {
        writeBlock(gMotionModal.format(0), zOutput.format(z), yOutput.format(y));
        writeBlock(gMotionModal.format(0), xOutput.format(cycle.retract));
      }
      writeBlock(
        gCycleModal.format(gCycleTapping),
        getCommonCycle(x, y, z, (gPlaneModal.getCurrent() == 19) ? undefined : cycle.retract),
        pitchOutput.format(F)
      );
      forceFeed();
      break;
    case "right-tapping":
      writeCycleClearance();
      xOutput.reset();
      if (gPlaneModal.getCurrent() == 19) {
        writeBlock(gMotionModal.format(0), zOutput.format(z), yOutput.format(y));
        writeBlock(gMotionModal.format(0), xOutput.format(cycle.retract));
      }
      writeBlock(
        gCycleModal.format(gCycleTapping),
        getCommonCycle(x, y, z, (gPlaneModal.getCurrent() == 19) ? undefined : cycle.retract),
        pitchOutput.format(F)
      );
      forceFeed();
      break;
    case "tapping-with-chip-breaking":
      writeCycleClearance();
      xOutput.reset();
      if (gPlaneModal.getCurrent() == 19) {
        writeBlock(gMotionModal.format(0), zOutput.format(z), yOutput.format(y));
        writeBlock(gMotionModal.format(0), xOutput.format(cycle.retract));
      }

      // Parameter 57 bit 6, REPT RIG TAP, is set to 1 (On)
      // On Mill software versions12.09 and above, REPT RIG TAP has been moved from the Parameters to Setting 133
      warningOnce(localize("For tapping with chip breaking make sure REPT RIG TAP (Setting 133) is enabled on your Haas."), WARNING_REPEAT_TAPPING);

      var u = cycle.stock;
      var step = cycle.incrementalDepth;
      var first = true;

      while (u > cycle.bottom) {
        if (step < cycle.minimumIncrementalDepth) {
          step = cycle.minimumIncrementalDepth;
        }
        u -= step;
        step -= cycle.incrementalDepthReduction;
        gCycleModal.reset(); // required
        u = Math.max(u, cycle.bottom);
        if (first) {
          first = false;
          writeBlock(
            gCycleModal.format(gCycleTapping),
            getCommonCycle((gPlaneModal.getCurrent() == 19) ? u : x, y, (gPlaneModal.getCurrent() == 19) ? z : u, (gPlaneModal.getCurrent() == 19) ? undefined : cycle.retract),
            pitchOutput.format(F)
          );
        } else {
          writeBlock(
            gCycleModal.format(gCycleTapping),
            conditional(gPlaneModal.getCurrent() == 18, "Z" + spatialFormat.format(u)),
            conditional(gPlaneModal.getCurrent() == 19, "X" + xFormat.format(u)),
            pitchOutput.format(F)
          );
        }
      }
      forceFeed();
      break;
    case "fine-boring":
      expandCyclePoint(x, y, z);
      break;
    case "reaming":
      if (gPlaneModal.getCurrent() == 19) {
        expandCyclePoint(x, y, z);
      } else {
        writeCycleClearance();
        forceXYZ();
        writeBlock(
          gCycleModal.format(85),
          getCommonCycle(x, y, z, cycle.retract),
          feedOutput.format(F)
        );
      }
      break;
    case "stop-boring":
      if (P > 0) {
        expandCyclePoint(x, y, z);
      } else {
        writeCycleClearance();
        forceXYZ();
        writeBlock(
          gCycleModal.format((gPlaneModal.getCurrent() == 19) ? 246 : 86),
          getCommonCycle(x, y, z, cycle.retract),
          feedOutput.format(F)
        );
      }
      break;
    case "boring":
      if (P > 0) {
        expandCyclePoint(x, y, z);
      } else {
        writeCycleClearance();
        forceXYZ();
        writeBlock(
          gCycleModal.format((gPlaneModal.getCurrent() == 19) ? 245 : 85),
          getCommonCycle(x, y, z, cycle.retract),
          feedOutput.format(F)
        );
      }
      break;
    default:
      expandCyclePoint(x, y, z);
    }
    if (!cycleExpanded) {
      writeBlock(gCycleModal.format(80));
      gMotionModal.reset();
    }
  } else {
    if (cycleExpanded) {
      expandCyclePoint(x, y, z);
    } else if (machineState.useXZCMode) {
      var _x = xOutput.format(getModulus(x, y));
      var _c = cOutput.format(getCWithinRange(x, y, cOutput.getCurrent()));
      if (!_x /*&& !_y*/ && !_c) {
        xOutput.reset(); // at least one axis is required
        _x = xOutput.format(getModulus(x, y));
      }
      writeBlock(_x, _c);
    } else {
      var _x = xOutput.format(x);
      var _y = yOutput.format(y);
      var _z = zOutput.format(z);
      if (!_x && !_y && !_z) {
        switch (gPlaneModal.getCurrent()) {
        case 18: // ZX
          xOutput.reset(); // at least one axis is required
          yOutput.reset(); // at least one axis is required
          _x = xOutput.format(x);
          _y = yOutput.format(y);
          break;
        case 19: // YZ
          yOutput.reset(); // at least one axis is required
          zOutput.reset(); // at least one axis is required
          _y = yOutput.format(y);
          _z = zOutput.format(z);
          break;
        }
      }
      writeBlock(_x, _y, _z);
    }
  }
}

function onCycleEnd() {
  if (!cycleExpanded && !machineState.stockTransferIsActive && !((typeof isSubSpindleCycle == "function") && isSubSpindleCycle(cycleType)) &&
      cycleType != "turning-canned-rough") {
    switch (cycleType) {
    case "thread-turning":
      forceFeed();
      g92IOutput.reset();
      g92QOutput.reset();
      gCycleModal.reset();
      xOutput.reset();
      zOutput.reset();
      if (threadNumber == numberOfThreads) {
        threadNumber = 0;
      }
      break;
    default:
      writeBlock(gCycleModal.format(80));
      gMotionModal.reset();
    }
  }
}

function onPassThrough(text) {
  writeBlock(text);
}

function onParameter(name, value) {
  if (name == "action") {
    if (String(value).toUpperCase() == "USEXZCMODE") {
      forceXZCMode = true;
    } else if (String(value).toUpperCase() == "USEPOLARMODE") {
      forcePolarMode = true;
    } else if (String(value).toUpperCase() == "PARTEJECT") {
      ejectRoutine = true;
    }
  }
}

var seenPatternIds = {};

function previewImage() {
  var permittedExtensions = ["JPG", "MP4", "MOV", "PNG", "JPEG"];
  var patternId = currentSection.getPatternId();
  var show = false;
  if (!seenPatternIds[patternId]) {
    show = true;
    seenPatternIds[patternId] = true;
  }
  var images = [];
  if (show) {
    if (FileSystem.isFile(FileSystem.getCombinedPath(FileSystem.getFolderPath(getOutputPath()), modelImagePath))) {
      images.push(modelImagePath);
    }
    if (hasParameter("autodeskcam:preview-name") && FileSystem.isFile(FileSystem.getCombinedPath(FileSystem.getFolderPath(getOutputPath()), getParameter("autodeskcam:preview-name")))) {
      images.push(getParameter("autodeskcam:preview-name"));
    }

    for (var i = 0; i < images.length; ++i) {
      var fileExtension = images[i].slice(images[i].lastIndexOf(".") + 1, images[i].length).toUpperCase();
      var permittedExtension = false;
      for (var j = 0; j < permittedExtensions.length; ++j) {
        if (fileExtension == permittedExtensions[j]) {
          permittedExtension = true;
          break; // found
        }
      }
      if (!permittedExtension) {
        warning(localize("The image file format " + "\"" + fileExtension + "\"" + " is not supported on HAAS controls."));
      }

      if (!getProperty("useM130PartImages") || !permittedExtension) {
        FileSystem.remove(FileSystem.getCombinedPath(FileSystem.getFolderPath(getOutputPath()), images[i])); // remove
        images.splice([i], 1); // remove from array
      }
    }
    if (images.length > 0) {
      writeBlock(mFormat.format(130), "(" + images[images.length - 1] + ")");
    }
  }
}

var currentCoolantMode = COOLANT_OFF;
var currentCoolantTurret = 1;
var coolantOff = undefined;
var isOptionalCoolant = false;
var forceCoolant = false;

function setCoolant(coolant, turret) {
  var coolantCodes = getCoolantCodes(coolant, turret);
  if (Array.isArray(coolantCodes)) {
    if (singleLineCoolant) {
      skipBlock = isOptionalCoolant;
      writeBlock(coolantCodes.join(getWordSeparator()));
    } else {
      for (var c in coolantCodes) {
        skipBlock = isOptionalCoolant;
        writeBlock(coolantCodes[c]);
      }
    }
    return undefined;
  }
  return coolantCodes;
}

function getCoolantCodes(coolant, turret) {
  turret = gotMultiTurret ? (turret == undefined ? 1 : turret) : 1;
  isOptionalCoolant = false;
  var multipleCoolantBlocks = new Array(); // create a formatted array to be passed into the outputted line
  if (!coolants) {
    error(localize("Coolants have not been defined."));
  }
  if (tool.type == TOOL_PROBE) { // avoid coolant output for probing
    coolant = COOLANT_OFF;
  }
  if (coolant == currentCoolantMode && turret == currentCoolantTurret) {
    if ((typeof operationNeedsSafeStart != "undefined" && operationNeedsSafeStart) && coolant != COOLANT_OFF) {
      isOptionalCoolant = true;
    } else if (!forceCoolant || coolant == COOLANT_OFF) {
      return undefined; // coolant is already active
    }
  }
  if ((coolant != COOLANT_OFF) && (currentCoolantMode != COOLANT_OFF) && (coolantOff != undefined) && !forceCoolant && !isOptionalCoolant) {
    if (Array.isArray(coolantOff)) {
      for (var i in coolantOff) {
        multipleCoolantBlocks.push(coolantOff[i]);
      }
    } else {
      multipleCoolantBlocks.push(coolantOff);
    }
  }
  forceCoolant = false;

  var m;
  var coolantCodes = {};
  for (var c in coolants) { // find required coolant codes into the coolants array
    if (coolants[c].id == coolant) {
      var localCoolant = parseCoolant(coolants[c], turret);
      localCoolant = typeof localCoolant == "undefined" ? coolants[c] : localCoolant;
      coolantCodes.on = localCoolant.on;
      if (localCoolant.off != undefined) {
        coolantCodes.off = localCoolant.off;
        break;
      } else {
        for (var i in coolants) {
          if (coolants[i].id == COOLANT_OFF) {
            coolantCodes.off = localCoolant.off;
            break;
          }
        }
      }
    }
  }
  if (coolant == COOLANT_OFF) {
    m = !coolantOff ? coolantCodes.off : coolantOff; // use the default coolant off command when an 'off' value is not specified
  } else {
    coolantOff = coolantCodes.off;
    m = coolantCodes.on;
  }

  if (!m) {
    onUnsupportedCoolant(coolant);
    m = 9;
  } else {
    if (Array.isArray(m)) {
      for (var i in m) {
        multipleCoolantBlocks.push(m[i]);
      }
    } else {
      multipleCoolantBlocks.push(m);
    }
    currentCoolantMode = coolant;
    currentCoolantTurret = turret;
    for (var i in multipleCoolantBlocks) {
      if (typeof multipleCoolantBlocks[i] == "number") {
        multipleCoolantBlocks[i] = mFormat.format(multipleCoolantBlocks[i]);
      }
    }
    return multipleCoolantBlocks; // return the single formatted coolant value
  }
  return undefined;
}

function parseCoolant(coolant, turret) {
  var localCoolant;
  if (getSpindle(true) == SPINDLE_MAIN) {
    localCoolant = turret == 1 ? coolant.spindle1t1 : coolant.spindle1t2;
    localCoolant = typeof localCoolant == "undefined" ? coolant.spindle1 : localCoolant;
  } else if (getSpindle(true) == SPINDLE_LIVE) {
    localCoolant = turret == 1 ? coolant.spindleLivet1 : coolant.spindleLivet2;
    localCoolant = typeof localCoolant == "undefined" ? coolant.spindleLive : localCoolant;
  } else {
    localCoolant = turret == 1 ? coolant.spindle2t1 : coolant.spindle2t2;
    localCoolant = typeof localCoolant == "undefined" ? coolant.spindle2 : localCoolant;
  }
  localCoolant = typeof localCoolant == "undefined" ? (turret == 1 ? coolant.turret1 : coolant.turret2) : localCoolant;
  localCoolant = typeof localCoolant == "undefined" ? coolant : localCoolant;
  return localCoolant;
}

function onCommand(command) {
  switch (command) {
  case COMMAND_COOLANT_OFF:
    setCoolant(COOLANT_OFF);
    break;
  case COMMAND_COOLANT_ON:
    setCoolant(tool.coolant);
    break;
  case COMMAND_START_SPINDLE:
    if (machineState.isTurningOperation || machineState.axialCenterDrilling) {
      if (currentSection.spindle == SPINDLE_PRIMARY) {
        writeBlock(tool.clockwise ? getCode("START_MAIN_SPINDLE_CW") : getCode("START_MAIN_SPINDLE_CCW"));
      } else {
        writeBlock(tool.clockwise ? getCode("START_SUB_SPINDLE_CW") : getCode("START_SUB_SPINDLE_CCW"));
      }
    } else {
      writeBlock(tool.clockwise ? getCode("START_LIVE_TOOL_CW") : getCode("START_LIVE_TOOL_CCW"));
    }
    break;
  case COMMAND_STOP_SPINDLE:
    if (getProperty("useSSV")) {
      writeBlock(ssvModal.format(39));
    }
    writeBlock(getCode("STOP_SPINDLE"));
    break;
  case COMMAND_LOCK_MULTI_AXIS:
    writeBlock(getCode((currentSection.spindle == SPINDLE_PRIMARY) ? "MAIN_SPINDLE_BRAKE_ON" : "SUB_SPINDLE_BRAKE_ON"));
    break;
  case COMMAND_UNLOCK_MULTI_AXIS:
    writeBlock(getCode((currentSection.spindle == SPINDLE_PRIMARY) ? "MAIN_SPINDLE_BRAKE_OFF" : "SUB_SPINDLE_BRAKE_OFF"));
    break;
  case COMMAND_START_CHIP_TRANSPORT:
    writeBlock(getCode("START_CHIP_TRANSPORT"));
    break;
  case COMMAND_STOP_CHIP_TRANSPORT:
    writeBlock(getCode("STOP_CHIP_TRANSPORT"));
    break;
  case COMMAND_OPEN_DOOR:
    if (gotDoorControl) {
      writeBlock(getCode("OPEN_DOOR")); // optional
    }
    break;
  case COMMAND_CLOSE_DOOR:
    if (gotDoorControl) {
      writeBlock(getCode("CLOSE_DOOR")); // optional
    }
    break;
  case COMMAND_BREAK_CONTROL:
    break;
  case COMMAND_TOOL_MEASURE:
    break;
  case COMMAND_ACTIVATE_SPEED_FEED_SYNCHRONIZATION:
    break;
  case COMMAND_DEACTIVATE_SPEED_FEED_SYNCHRONIZATION:
    break;
  case COMMAND_STOP:
    if (!skipBlock) {
      forceSpindleSpeed = true;
      forceCoolant = true;
    }
    writeBlock(mFormat.format(0));
    break;
  case COMMAND_OPTIONAL_STOP:
    if (!skipBlock) {
      forceSpindleSpeed = true;
      forceCoolant = true;
    }
    writeBlock(mFormat.format(1));
    break;
  case COMMAND_END:
    writeBlock(mFormat.format(2));
    break;
  case COMMAND_ORIENTATE_SPINDLE:
    if (machineState.isTurningOperation) {
      if (currentSection.spindle == SPINDLE_PRIMARY) {
        writeBlock(mFormat.format(19)); // use P or R to set angle (optional)
      } else {
        writeBlock(mFormat.format(g14IsActive ? 19 : 119));
      }
    } else {
      if (isSameDirection(currentSection.workPlane.forward, new Vector(0, 0, 1))) {
        writeBlock(mFormat.format(19)); // use P or R to set angle (optional)
      } else if (isSameDirection(currentSection.workPlane.forward, new Vector(0, 0, -1))) {
        writeBlock(mFormat.format(g14IsActive ? 19 : 119));
      } else {
        error(localize("Spindle orientation is not supported for live tooling."));
        return;
      }
    }
    break;
  // case COMMAND_CLAMP: // add support for clamping
  // case COMMAND_UNCLAMP: // add support for clamping
  default:
    onUnsupportedCommand(command);
  }
}

/** Preload cutoff tool prior to spindle transfer/cutoff. */
var prePositionCutoffTool = true;
function preloadCutoffTool() {
  if (isLastSection()) {
    return;
  }
  var numberOfSections = getNumberOfSections();
  for (var i = getNextSection().getId(); i < numberOfSections; ++i) {
    var section = getSection(i);
    if (section.getParameter("operation-strategy") == "turningSecondarySpindleReturn") {
      continue;
    } else if (section.getType() != TYPE_TURNING || section.spindle != SPINDLE_PRIMARY) {
      break;
    } else if (section.getParameter("operation-strategy") == "turningPart") {
      var tool = section.getTool();
      var compensationOffset = tool.compensationOffset;
      writeBlock("T" + toolFormat.format(tool.number * 100 + compensationOffset));
      if (prePositionCutoffTool) {
        var initialPosition = getFramePosition(section.getInitialPosition());
        writeBlock(zOutput.format(initialPosition.z));
      }
      break;
    }
  }
  return;
}

/** Get synchronization/transfer code based on part cutoff spindle direction. */
function getSpindleTransferCodes() {
  var transferCodes = {direction:0, spindleMode:SPINDLE_CONSTANT_SPINDLE_SPEED, surfaceSpeed:0, maximumSpindleSpeed:0};
  transferCodes.spindleDirection = isFirstSection() ? true : getPreviousSection().getTool().clockwise; // clockwise
  transferCodes.spindleRPM = cycle.spindleSpeed;
  if (isLastSection()) {
    return transferCodes;
  }
  var numberOfSections = getNumberOfSections();
  for (var i = getNextSection().getId(); i < numberOfSections; ++i) {
    var section = getSection(i);
    if (section.getParameter("operation-strategy") == "turningSecondarySpindleReturn") {
      continue;
    } else if (section.getType() != TYPE_TURNING || section.spindle != SPINDLE_PRIMARY) {
      break;
    } else if (section.getType() == TYPE_TURNING) {
      var tool = section.getTool();
      transferCodes.spindleMode = tool.getSpindleMode();
      transferCodes.surfaceSpeed = tool.surfaceSpeed;
      transferCodes.maximumSpindleSpeed = tool.maximumSpindleSpeed;
      transferCodes.spindleDirection = tool.clockwise;
      break;
    }
  }
  return transferCodes;
}

function engagePartCatcher(engage) {
  if (engage) {
    // catch part here
    writeBlock(getCode("PART_CATCHER_ON"), formatComment(localize("PART CATCHER ON")));
  } else {
    onCommand(COMMAND_COOLANT_OFF);
    if (gotYAxis) {
      writeBlock(gFormat.format(53), gMotionModal.format(0), "Y" + yFormat.format(machineConfiguration.getHomePositionY())); // retract
      yOutput.reset();
    }
    writeBlock(gFormat.format(53), gMotionModal.format(0), "X" + xFormat.format(machineConfiguration.getHomePositionX())); // retract
    writeBlock(gFormat.format(53), gMotionModal.format(0), "Z" + zFormat.format(currentSection.spindle == SPINDLE_SECONDARY ? g53HomePositionSubZ : machineConfiguration.getRetractPlane())); // retract
    writeBlock(getCode("PART_CATCHER_OFF"), formatComment(localize("PART CATCHER OFF")));
    forceXYZ();
  }
}

function ejectPart() {
  writeln("");
  writeComment(localize("PART EJECT"));

  gMotionModal.reset();
  //writeBlock(gFormat.format(330)); // retract bar feeder
  //goHome(); // Position all axes to home position

  if (gotYAxis) {
    writeBlock(gFormat.format(53), gMotionModal.format(0), "Y" + yFormat.format(machineConfiguration.getHomePositionY())); // retract
    yOutput.reset();
  }
  writeBlock(gFormat.format(53), gMotionModal.format(0), "X" + xFormat.format(machineConfiguration.getHomePositionX())); // retract
  writeBlock(gFormat.format(53), gMotionModal.format(0), "Z" + zFormat.format(currentSection.spindle == SPINDLE_SECONDARY ? g53HomePositionSubZ : machineConfiguration.getRetractPlane())); // retract

  onCommand(COMMAND_UNLOCK_MULTI_AXIS);
  writeBlock(
    getCode("FEED_MODE_UNIT_MIN"),
    gPlaneModal.format(17)
    // getCode("DISENGAGE_C_AXIS")
  );
  // setCoolant(COOLANT_THROUGH_TOOL);
  gSpindleModeModal.reset();
  writeBlock(
    getCode("CONSTANT_SURFACE_SPEED_OFF"),
    sOutput.format(50),
    getCode(currentSection.spindle == SPINDLE_SECONDARY ? "START_SUB_SPINDLE_CW" : "START_MAIN_SPINDLE_CW")
  );
  // writeBlock(mFormat.format(getCode("INTERLOCK_BYPASS", getSpindle(true))));
  writeBlock(getCode("PART_CATCHER_ON"));
  writeBlock(getCode(currentSection.spindle == SPINDLE_SECONDARY ? "UNCLAMP_SECONDARY_CHUCK" : "UNCLAMP_PRIMARY_CHUCK"));
  onDwell(1.5);
  // writeBlock(mFormat.format(getCode("CYCLE_PART_EJECTOR")));
  // onDwell(0.5);
  writeBlock(getCode("PART_CATCHER_OFF"));
  onDwell(1.1);

  // clean out chips
  if (getProperty("cleanAir")) {
    writeBlock(getCode(currentSection.spindle == SPINDLE_SECONDARY ? "SUBSPINDLE_AIR_BLAST_ON" : "MAINSPINDLE_AIR_BLAST_ON"),
      formatComment("AIR BLAST ON"));
    onDwell(2.5);
    writeBlock(getCode(currentSection.spindle == SPINDLE_SECONDARY ? "SUBSPINDLE_AIR_BLAST_OFF" : "MAINSPINDLE_AIR_BLAST_OFF"),
      formatComment("AIR BLAST OFF"));
  }
  writeBlock(getCode("STOP_SPINDLE"));
  setCoolant(COOLANT_OFF);
  writeComment(localize("END OF PART EJECT"));
  writeln("");
}

function onSectionEnd() {

  if (currentSection.partCatcher) {
    engagePartCatcher(false);
  }

  if (machineState.usePolarMode) {
    setPolarMode(false); // disable polar interpolation mode
  }

  // cancel SFM mode to preserve spindle speed
  if ((tool.getSpindleMode() == SPINDLE_CONSTANT_SURFACE_SPEED) && !machineState.stockTransferIsActive) {
    startSpindle(true, getFramePosition(currentSection.getFinalPosition()));
  }

  if (getProperty("useG61")) {
    writeBlock(gExactStopModal.format(64));
  }

  if (((getCurrentSectionId() + 1) >= getNumberOfSections()) ||
      (tool.number != getNextSection().getTool().number)) {
    onCommand(COMMAND_BREAK_CONTROL);
  }

  if ((currentSection.getType() == TYPE_MILLING) &&
      (!hasNextSection() || (hasNextSection() && (getNextSection().getType() != TYPE_MILLING)))) {
    // exit milling mode
    if (isSameDirection(currentSection.workPlane.forward, new Vector(0, 0, 1))) {
      // +Z
    } else {
      writeBlock(getCode("STOP_SPINDLE"));
    }
  }

  if (machineState.useXZCMode || currentSection.isMultiAxis()) {
    writeBlock(getCode("FEED_MODE_UNIT_MIN"));
  }

  // the code below gets the machine angles from previous operation.  closestABC must also be set to true
  if (currentSection.isMultiAxis() && currentSection.isOptimizedForMachine()) {
    currentMachineABC = currentSection.getFinalToolAxisABC();
  }

  forceAny();
  forcePolarMode = false;
  partCutoff = false;
}

/** Output block to do safe retract in Z for head machine. */
function writeRetractSafeZ(position, bAngle) {
  if (typeof position != "number") {
    forceXYZ();
    writeBlock(
      gMotionModal.format(0),
      xOutput.format(position.x),
      yOutput.format(position.y),
      zOutput.format(position.z),
      bAngle
    );
  } else {
    zOutput.reset();
    writeBlock(
      gMotionModal.format(0),
      zOutput.format(position)
    );
  }
}

function onClose() {
  writeln("");

  optionalSection = false;

  onCommand(COMMAND_COOLANT_OFF);

  if (getProperty("gotChipConveyor")) {
    onCommand(COMMAND_STOP_CHIP_TRANSPORT);
  }

  cancelWorkPlane();
  writeRetract(Y, Z);
  writeRetract(X, B);

  if (machineState.tailstockIsActive) {
    writeBlock(getCode("TAILSTOCK_OFF"));
  }

  gMotionModal.reset();

  if (ejectRoutine) {
    ejectPart();
  }

  if (getProperty("useBarFeeder")) {
    writeln("");
    writeComment(localize("Bar feed"));
    // feed bar here
    // writeBlock(gFormat.format(53), gMotionModal.format(0), "X" + machineConfiguration.getHomePositionX()));
    writeBlock(gFormat.format(105));
  }

  writeln("");
  onImpliedCommand(COMMAND_END);
  onImpliedCommand(COMMAND_STOP_SPINDLE);

  if (getProperty("useM130PartImages") || getProperty("useM130ToolImages")) {
    writeBlock(mFormat.format(131));
  }

  if (getProperty("looping")) {
    writeBlock(mFormat.format(99));
  } else if (true /*!getProperty("useM97")*/) {
    onCommand(COMMAND_OPEN_DOOR);
    writeBlock(mFormat.format(getProperty("useBarFeeder") ? 99 : 30)); // stop program, spindle stop, coolant off
  } else {
    writeBlock(mFormat.format(99));
  }
  writeln("%");
}

function setProperty(property, value) {
  properties[property].current = value;
}
