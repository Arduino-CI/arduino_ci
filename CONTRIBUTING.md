# Contributing to the ArduinoCI gem

ArduinoCI uses a very standard GitHub workflow.

1. Fork the repository on github
2. Make your desired changes
3. Push to your personal fork
4. Open a pull request

Pull requests will trigger a Travis CI job.  The following two commands will be expected to pass (so you may want to run them locally before opening the pull request):

 * `rubocop -D` - code style tests
 * `rspec` - functional tests

 If you do not already have a working ruby development environment set up, run the following commands:

```shell
apt-get install ruby ruby-dev    # For Debian/Ubuntu
dnf install ruby ruby-devel      # For Fedora
yum install ruby ruby-devel      # For Centos/RHEL
gem install bundler
gem install rubocop
gem install rspec
```

Be prepared to write tests to accompany any code you would like to see merged.
See `SampleProjects/TestSomething/test/*.cpp` for the existing tests (run by rspec).


## Packaging the Gem

* Merge pull request with new features
* `git stash save` (at least before the gem build step, but easiest here).
* `git pull --rebase`
* Update the sections of `CHANGELOG.md` by running `bundle exec keepachangelog_release.md --increment-patch`
* Bump the version in lib/arduino_ci/version.rb and change it in README.md (since rubydoc.info doesn't always redirect to the latest version)
* `git add README.md CHANGELOG.md lib/arduino_ci/version.rb`
* `git commit -m "vVERSION bump"`
* `git tag -a vVERSION -m "Released version VERSION"`
* `gem build arduino_ci.gemspec`
* `git stash pop`
* `gem push arduino_ci-VERSION.gem`
* `git push upstream`
* `git push upstream --tags`
* Visit http://www.rubydoc.info/gems/arduino_ci/VERSION to initiate the doc generation process
