require "spec_helper"
require "fileutils"
require "fontcustom/watcher"

describe Fontcustom::Watcher do
  # Silence messages without passing :quiet => true to everything
  #before(:each) do
    #Fontcustom::Options.any_instance.stub :say_message
  #end

  def watcher(options)
    Fontcustom::Manifest.any_instance.stub :write_file
    Fontcustom::Base.any_instance.stub :compile

    # undocumented — non-blocking use of watcher for testing
    Fontcustom::Watcher.new options, true
  end

  context "#watch" do
    it "should compile on init" do
      Fontcustom::Base.any_instance.should_receive(:compile).once

      w = watcher(
        :input => "shared/vectors",
        :output => "output"
      )

      # silence output
      capture(:stdout) do
        w.watch
        w.send :stop
      end
    end

    it "should not call generators on init if options[:skip_first] is passed" do
      Fontcustom::Base.any_instance.should_not_receive(:compile)

      w = watcher(
        :input => "shared/vectors",
        :output => "output",
        :skip_first => true
      )

      capture(:stdout) do
        w.watch
        w.send :stop
      end
    end

    it "should call generators when vectors change" do
      Fontcustom::Base.any_instance.should_receive(:compile).once

      w = watcher(
        :input => "shared/vectors",
        :output => "output",
        :skip_first => true
      )

      capture(:stdout) do
        begin
          w.watch
          FileUtils.cp fixture("shared/vectors/C.svg"), fixture("shared/vectors/test.svg")
          sleep 1
        ensure
          w.send :stop
          new = fixture("shared/vectors/test.svg")
          FileUtils.rm(new) if File.exists?(new)
        end
      end
    end

    it "should call generators when custom templates change" do
      Fontcustom::Base.any_instance.should_receive(:compile).once

      w = watcher(
        :input => {:vectors => "shared/vectors", :templates => "shared/templates"},
        :templates => %w|css preview custom.css|,
        :output => "output",
        :skip_first => true
      )

      capture(:stdout) do
        begin
          template = fixture "shared/templates/custom.css"
          content = File.read template
          new = content + "\n.bar { color: red; }"

          w.watch
          File.open(template, "w") { |file| file.write(new) }
          sleep 1
        ensure
          w.send :stop
          File.open(template, "w") { |file| file.write(content) }
        end
      end

    end

    it "should do nothing when non-vectors change" do
      Fontcustom::Base.any_instance.should_not_receive(:compile)

      w = watcher(
        :input => "shared/vectors",
        :output => "output",
        :skip_first => true
      )

      capture(:stdout) do
        begin
          w.watch
          FileUtils.touch fixture("shared/vectors/non-vector-file")
        ensure
          w.send :stop
          new = fixture("shared/vectors/non-vector-file")
          FileUtils.rm(new) if File.exists?(new)
        end
      end
    end
  end
end
