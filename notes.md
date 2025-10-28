# Notes

* `TUI_CONFIG_FILE` in `tui-lib.sh` is unused
* We are loading YAML config with `yq`, converting it to JSON and then using
  `jq` to parse it. Use YAML directly.
* Related to previous point, functions for parsing this config are unreadable
* Callbacks have to be full path to file, can't use commands
* Why are we exporting functions at least ones that likely shouldn't be used by
  backend like `tui_stop`
* We should split `tui-lib.sh` into lib that should be used by scripts to print
  something, and core lib used to run menu.
* Add input parsing in menu to disallow multiline strings (or deal with them
  correctly)
* Add right border (and handle too long strings)
* callback can't have arguments
* conditions can only be variables
* `tui_handle_input`
    - `# Hidden option: Q to quit (useful for testing)` - I am very apprehensive
      about `hidden` part.
    - I thought this function was to be used by other scripts, but it shouldn't
      as this function is to handle menu input. We really need to separate core
      functions, internal to the UI.
* Missing various input, prompt, choice, etc. functions
* We can only print lines (with newline at the end), if we want to print
    multicolor line we have to use workarounds such as:

    ```sh
    tui_echo_normal "$(tui_echo_red ERROR:) $(tui_echo_yellow warning)"
    ```

    we should have clear split between functions that should only be used to
    print on screen and functions that should be used to e.g. pass strings
    between functions, variables etc. In the future, we could make sure that
    we only show text that is printed via those screen printing functions
* Find better way to do submenus - in DTS menu was generated dynamically so I
  created temporary `yaml` and ran `tui_run <path_to_new_config>"`
* `Enter an option:|` cursor is too close (add space) `Enter an option: |`
* Allow using commands instead of shell variables?
* Missing utility functions related to e.g. asking for user choice e.g.:
  <https://github.com/Dasharo/dts-scripts/blob/7b43513360816fc2171161b39c2a4bc79f88f487/include/dts-functions.sh#L1921>
* Feature: we could force usage of TUI printing functions to print anything on
  screen. Usage of `echo` wouldn't print anything, and could be used to pass
  strings between functions in shell script.
* DTS related:
    - delay before refresh after pressing any, non-mapped key (likely due to
      `subscription_routine` or other pre-render callbacks)
    - long black screen when using footer options, probably the same reason as
      before, screen is cleared, `pre-render` callbacks are running and only
      after that we render UI
    - Extensions in DTS extensions submenu might not work
