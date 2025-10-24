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
* Find better way to do submenus
