# dovetail

dovetail is an opinionated window manager based on
[awesome](https://awesomewm.org/).

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
    * [sessiond](https://sessiond.org/) as a session manager
        * Locks the screen on session idle.
        * Use rules to make specific clients inhibit idling.
    * [wm-launch](https://github.com/jcrd/wm-launch) to identify clients
        * Clients can be reliably assigned to workspaces.
    * Built-in `pulseaudio` control with visual feedback
    * Optionally use `upower` to display laptop battery stats

## Packages

* **RPM** package available from [copr][copr]. [![Copr build status](https://copr.fedorainfracloud.org/coprs/jcrd/dovetail/package/dovetail/status_image/last_build.png)](https://copr.fedorainfracloud.org/coprs/jcrd/dovetail/package/dovetail/)

  Install with:
  ```
  dnf copr enable jcrd/dovetail
  dnf install dovetail
  ```

[copr]: https://copr.fedorainfracloud.org/coprs/jcrd/dovetail/

## Getting started

After installing dovetail, enable the service with
`systemctl --user enable dovetail`.

Now, start a `sessiond session` via your display manager.

See [Session management](https://sessiond.org/session-management/) for
information about running other services in this session.

### Workspace navigation

In dovetail, workspaces are volatile: they exist only if non-empty. At startup,
the main workspace, which always exists, will be selected.  With this in mind,
we can navigate to a new workspace using (by default) one of these keybindings:

* `Meta-2` to select the second workspace
* `Meta-Shift-j` to select the next workspace
* `Meta-Shift-k` to select the previous workspace (wraps at the beginning of the
  workspace list)

With the second workspace selected, pressing any of the above keybindings will
select the main workspace, and the second workspace will cease to exist. This is
because pressing `Meta-2` while the second workspace is already selected will
select the previously selected workspace. The `Meta-Shift-{j,k}` keybindings
wrap at the boundaries of the workspace list. Because the second workspace does
not contain clients, it is removed upon unselection.

### Client navigation

In dovetail, there can be at most two visible tiled clients: the top client in
the stack, and the master client. Newly spawned clients enter the stack. To set
a client as the master, use `Meta-s`. This will replace the current master.
Toggle focus between the master and top stack client with `Meta-f`. Use `Meta-j`
and `Meta-k` to focus the next and previous client in the stack, respectively.
Close clients with `Meta-Shift-d`.

See [config.def.lua](config.def.lua) for all default keybindings.

## License

This project is licensed under the MIT License (see [LICENSE](LICENSE)).
