## Note to `arduino_ci` users

In this project, we define a workflow for each target platform.  **If you're looking for an example you can copy from, take only `linux.yaml`.**


### Long version

The reason that all platforms are tested in _this_ project is to ensure that, as a framework, `arduino_ci` will run properly on any developer's personal workstation (regardless of OS).

For testing an individual Arduino library in the context of GitHub, [Linux is the cheapest option](https://docs.github.com/en/free-pro-team@latest/github/setting-up-and-managing-billing-and-payments-on-github/about-billing-for-github-actions) and should produce results identical to the other OSes.
