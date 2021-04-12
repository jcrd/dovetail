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

## License

This project is licensed under the MIT License (see [LICENSE](LICENSE)).
