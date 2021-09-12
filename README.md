# dovetail

dovetail is an opinionated window manager based on
[awesome](https://awesomewm.org/).

![](https://github.com/jcrd/dovetail/blob/assets/desktop_screenshot.png)

## What makes it opinionated?

1. The paradigm
    * A single, specialized tiling layout
        * Simple, powerful tiling paradigm that unifies window and visibility management.
    * Virtual desktops as dynamically created workspaces
        * Spawn new workspaces and accompanying clients on the fly.
        * Only the workspaces you're using exist. Allows fast and intuitive navigation.
    * Largely ignores the mouse
        * The cursor is hidden by default.
    * Declarative configuration
        * Minimal theming.
        * Straightforward key and button binding.
        * Client rules.

2. Requires a modern, DBus-capable Linux environment
    * [sessiond][sessiond] as a session manager
        * Locks the screen on session idle.
        * Use rules to make specific clients inhibit idling.
    * [wm-launch][wm-launch] to identify clients
        * Clients can be reliably assigned to workspaces.
    * Built-in `pulseaudio` control with visual feedback
    * Optionally use `upower` to display laptop battery stats

[sessiond]: https://sessiond.org/
[wm-launch]: https://github.com/jcrd/wm-launch

## Packages

* **RPM** package available from [copr][copr]. [![Copr build status](https://copr.fedorainfracloud.org/coprs/jcrd/dovetail/package/dovetail/status_image/last_build.png)](https://copr.fedorainfracloud.org/coprs/jcrd/dovetail/package/dovetail/)

  Install with:
  ```
  dnf copr enable jcrd/dovetail
  dnf install dovetail
  ```

[copr]: https://copr.fedorainfracloud.org/coprs/jcrd/dovetail/

## Configuration

Copy the default configuration from `/etc/xdg/dovetail/config.lua` to
`~/.config/dovetail/config.lua` and edit as needed.

See the comments in [config.def.lua](config.def.lua) for descriptions of
options and bindings.

### Key and button bindings

Keys and buttons are bound to commands using this syntax: `<meta>-<mod>-<key>`.

`<meta>` can be one of:
  * `M` (super key, typically the *Windows* key)
  * `A` (alt key)

`<mod>` can be one of:
  * `S` (shift key)
  * `C` (control key)

`<key>` can be the name of any keysym as given by `xev`.

For example, the keybinding `M-S-Return` is triggered by pressing and holding
the super and shift keys, then pressing `Return`.

## Getting started

After installing dovetail, enable the service with
`systemctl --user enable dovetail`.

Now, start a `sessiond session` via your display manager.

See *sessiond*'s [Session management][management] for information about running
other services in this session.

[management]: https://sessiond.org/session-management/#running-services

### Workspace navigation

The workspace paradigm in dovetail follows these rules:
* workspaces exist only if non-empty
* a `main` workspace always exists

Navigate to a new workspace using (by default) these keybindings:

* `Meta-2` to select the second workspace
    * press again to select the previously selected workspace, in this case
      `main`
* `Meta-Shift-j` to select the next workspace
    * press again to wrap to the start of the workspace list, selecting `main`
* `Meta-Shift-k` to select the previous workspace
    * press again to wrap to the end of the workspace list, selecting `main`
* `Meta-Tab` to select the previously selected workspace, or the second if
  only `main` exists

If these keys are pressed again, the second workspace will be removed since it
does not contain clients.

#### Per-project workspaces

Project-specific workspaces are configured in a [`.workspace`][workspace-files]
file in a project's directory.

The default keybinding `M-w` opens a menu to create a new workspace based on the
selected project's `.workspace` file.

These files are searched for in the paths of the `workspace_search_paths`
option.

[workspace-files]: https://github.com/jcrd/wm-launch#workspace-files

### Client navigation

In dovetail, there can be at most two visible tiled clients: the top client in
the stack, and the master client. By default, a newly spawned client will enter
the stack.

Interact with clients using (by default) these keybindings:

* `Meta-s` to set the focused client as the master, replacing the current
  master
* `Meta-o` to toggle maximized state, effectively placing all clients in the
  stack
* `Meta-f` to toggle focus between the master and the top stack client
* `Meta-j` to focus the next client in the stack
* `Meta-k` to focus the previous client in the stack
* `Meta-Shift-d` to close the focused client

#### Client minimization

Minimized clients will be displayed in the bar but will not be visible.

Handle minimization using (by default) these keybindings:

* `Meta-x` to minimize the focused client
* `Meta-S-x` to restore the most recently minimized client
* `Meta-z` to minimize the focused client when a new client is launched

## Other features

### Inhibiting idle

dovetail can be configured to prevent the session from idling while a specific
client has focus, for example a media player.

This is set up in the `rules` section of the configuration file by setting
the `inhibit` option of a rule to `true`.

See *awesome*'s client rule [documentation][rule-docs] for more information.

[rule-docs]: https://awesomewm.org/apidoc/declarative_rules/ruled.client.html

### Screenshots

* `Print` takes a screenshot
* `S-Print` takes a screenshot of the specified region

Screenshots are by default saved to `~/screenshots`. This location can be
customized with the option `screenshot_directory`.

## Building

### Dependencies

* awesome == latest *[runtime]*
    * dovetail currently tracks awesome's [master branch][master]
* luarocks *[build]*
* make *[build]*
* bash *[runtime]*
* pulseaudio *[runtime]*
* rofi *[runtime]*
* sessiond >= 0.5.0 *[runtime]*
* wm-launch >= 0.5.0 *[runtime]*

* ImageMagick *[runtime,optional]*
    * for screenshot feature
* upower *[runtime,optional]*
    * for laptop battery stats feature

[master]: https://github.com/awesomeWM/awesome

Ensure the above build dependencies are satisfied and run: `make`.

### Installing

Install with `make install`.

## License

This project is licensed under the MIT License (see [LICENSE](LICENSE)).
