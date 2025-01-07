# rF2ImpulseTachGenerator

A nonlinear gauge code generator for simulating historic impulse-like tach in `rF2`.

This tool works around `rF2` limitation by creating special nonlinear gauge code to restrict gauge needle movement at specific range, which allows an approximate simulation of impulse-like needle movement for historic tachometer or other gauges.

Both `linear scale` & `nonlinear scale` type gauge is supported in this tool.

![preview](https://github.com/user-attachments/assets/655e42f3-3f0d-4712-889c-42c19054529c)


## Usage

### Generate gauge code
1. Select a gauge type from `Gauge Type` drop-down list.
2. Click `Generate` to generate step code. Newly generated code will be output to `CockpitInfo` & `Upgrades` tabs.
3. Click `Stop` any time to stop a generating process.
4. Click `Save As` to save code to a text file for later use.

### Apply code to CockpitInfo.ini
1. Select `CockpitInfo` tab.
2. Click `Copy to Clipboard` to copy all code from `CockpitInfo` tab to Clipboard.
3. Open `cockpitinfo.ini` file from a rF2 vehicle mod with `text editor`.
4. Paste generated code to the end of `cockpitinfo.ini` file and save, done.  
Note, any changes to `CockpitInfo.ini` file will not take effect until a session is restarted from main menu.

### Apply code to Upgrades.ini
1. Select `Upgrades` tab.
2. Click `Copy to Clipboard` to copy all code from `Upgrades` tab to Clipboard.
3. Open `Upgrades.ini` file from a rF2 vehicle mod with `text editor`.
4. Paste generated code to the end of `Upgrades.ini` file and save.  
Note, if `rF2` Dev Mode is already running, any changes to `Upgrades.ini` file will not take effect until `rF2` is restarted.
5. Start `rF2` Dev Mode, select vehicle and go to `Tuning`, select `Impulse Tachometer` > `Enable` from `Upgrade`, done.  

Using `Upgrades.ini` method is more flexible for toggling impulse effect on and off based on preference and can be easily added to any existing mods, while `CockpitInfo.ini` method is easier for debugging in Dev Mode.

Note, only one of the methods should be used on a vehicle mod at a time, otherwise may cause conflict between two methods. It is recommended to save code from both methods for later use.

### Configuration
- Gauge Type:
    - Set gauge type that used as prefix for output, which includes `Tachometer`, `Speedometer`, `WaterTemp`, `OilTemp`.
- Scale Mode:
    - Set scale mode for `Linear` or `Nonlinear` gauge.
    - `Linear` scale mode generates code based on `Average Step` and other `Parameters` options.
    - `Nonlinear` scale mode generates code based on values set in `Target` & `Scale` columns from nonlinear scale table, and is affected by `Smooth Range` from `Parameters` options.
- Add Comments:
    - Add step info comment to generated code.

### Parameters
- Maximum Value:
    - Set maximum value according to gauge's capacity. Only used in `Linear` scale mode.
    - For `Tachometer`, this value represents `RPM`.
    - For `Speedometer`, this value represents `KPH`.
    - For `WaterTemp`, `OilTemp`, this value represents `degree`.
- Minimum Value:
    - Set minimum value for the starting impulse step, negative value is supported. Only used in `Linear` scale mode.
- Average Step:
    - Set average range value for each impulse step. Only used in `Linear` scale mode.
- Random Range:
    - Add random amount positive or negative variation to each impulse step. For example, a `200` value sets a random range in `-200` to `+200`, and a value will be randomly picked from this range for each generating process and step. Only used in `Linear` scale mode.
- Smooth Range:
    - Set amount smooth transition to needle movement between each impulse step. A `0` value makes needle move instantly between steps.
- Linear Scale:
    - Set constant linear scale for generating code while in `Linear` scale mode.

### Nonlinear Scale Table
- Target Column
    - `Target` column is available after enabled `Nonlinear` scale mode. Each row sets a target value corresponding to unscaled gauge reading.
    - For `Tachometer`, this value represents `RPM`.
    - For `Speedometer`, this value represents `KPH`.
    - For `WaterTemp`, `OilTemp`, this value represents `degree`.
- Scale Column
    - `Scale` column is available after enabled `Nonlinear` scale mode. Each row sets a scale value that scales step range for next impulse step.

Note, there are total 30 rows in the table, empty rows are skipped and excluded from calculation and output. The table does not support inserting or removing rows, it is recommended to make a reference spreadsheet in other program for setting up the values.


## Requirements
This tool is written in [Autohotkey](https://www.autohotkey.com) scripting language, source script requires `Autohotkey v2` to run.


## License
rF2ImpulseTachGenerator is licensed under the [MIT License](./LICENSE.txt).
