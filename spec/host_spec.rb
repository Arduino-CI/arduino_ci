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

  context "path mangling" do
    win_path = "D:\\a\\_temp\\d20221224-4508-11w7f4\\foo.yml"
    posix_pathname = Pathname.new("D:/a/_temp/d20221224-4508-11w7f4/foo.yml")

    it "converts windows paths to pathnames" do
      expect(ArduinoCI::Host.pathname_to_windows(posix_pathname)).to eq(win_path)
    end

    it "converts pathnames to windows paths" do
      expect(ArduinoCI::Host.windows_to_pathname(win_path)).to eq(posix_pathname)
    end
  end

  context "merge_capture_results" do
    it "merges results" do
      a1 = { out: "one", err: "ONE", success: true }
      a2 = { out: "two", err: "TWO", success: false }
      a3 = { out: "three", err: "THREE", success: true }
      res = ArduinoCI::Host.merge_capture_results(a1, a2, a3)
      expect(res[:out]).to eq("onetwothree")
      expect(res[:err]).to eq("ONETWOTHREE")
      expect(res[:success]).to eq(false)
    end

    it "handles empty input" do
      res = ArduinoCI::Host.merge_capture_results()
      expect(res[:out]).to eq("")
      expect(res[:err]).to eq("")
      expect(res[:success]).to eq(true)
    end
  end

end
