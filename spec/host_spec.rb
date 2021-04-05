require "spec_helper"
require 'tmpdir'


def idempotent_delete(path)
  path.delete
rescue Errno::ENOENT
end

# creates a dir at <path> then deletes it after block executes
# this will DESTROY any existing entry at that location in the filesystem
def with_tmpdir(path)
  begin
    idempotent_delete(path)
    path.mkpath
    yield
  ensure
    idempotent_delete(path)
  end
end


RSpec.describe ArduinoCI::Host do
  next if skip_ruby_tests

  context "symlinks" do
    it "creates symlinks that we agree are symlinks" do
      our_dir = Pathname.new(__dir__)
      foo_dir = our_dir + "foo_dir"
      bar_dir = our_dir + "bar_dir"

      with_tmpdir(foo_dir) do
        foo_dir.unlink # we just want to place something at this location
        expect(foo_dir.exist?).to be_falsey

        with_tmpdir(bar_dir) do
          expect(bar_dir.exist?).to be_truthy
          expect(bar_dir.symlink?).to be_falsey

          ArduinoCI::Host.symlink(bar_dir, foo_dir)
          expect(ArduinoCI::Host.symlink?(bar_dir)).to be_falsey
          expect(ArduinoCI::Host.symlink?(foo_dir)).to be_truthy
          expect(ArduinoCI::Host.readlink(foo_dir).realpath).to eq(bar_dir.realpath)
        end
      end

      expect(foo_dir.exist?).to be_falsey
      expect(bar_dir.exist?).to be_falsey

    end
  end

  context "which" do
    it "can find things with which" do
      ruby_path = ArduinoCI::Host.which("ruby")
      expect(ruby_path).not_to be nil
      expect(ruby_path.to_s.include? "ruby").to be true
    end
  end

end
