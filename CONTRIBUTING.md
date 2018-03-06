# Contributing to the ArduinoCI gem

ArduinoCI uses a very standard GitHub workflow.

1. Fork the repository on github
2. Make your desired changes
3. Push to your personal fork
4. Open a pull request

Pull requests will trigger a Travis CI job.  The following two commands will be expected to pass (so you may want to run them locally before opening the pull request):

 * `rubocop -D` - code style tests
 * `rspec` - functional tests

Be prepared to write tests to accompany any code you would like to see merged.


## Packaging the Gem

* Merge pull request with new features
* `git pull --rebase`
* Bump the version in lib/arduino_ci/version.rb and change it in README.md (since rubydoc.info doesn't always redirect to the latest version)
* Update the sections of `CHANGELOG.md`
* `git add README.md CHANGELOG.md lib/arduino_ci/version.rb`
* `git commit -m "vVERSION bump"`
* `git tag -a vVERSION -m "Released version VERSION"`
* `gem build arduino_ci.gemspec`
* `gem push arduino_ci-VERSION.gem`
* `git push upstream`
* `git push upstream --tags`
