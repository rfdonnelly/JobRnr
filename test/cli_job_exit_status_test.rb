# frozen_string_literal: true

require "test_helper"

describe "CLI Job Exit Status" do
  def no_color(&block)
    ENV["NO_COLOR"] = "1"
    block.call
    ENV.delete("NO_COLOR")
  end

  def assert_io_matches(exp_out, exp_err, &block)
    out, err = capture_io do
      no_color do
        speedup do
          Kernel.stub(:trap, nil, &block)
        end
      end
    end

    expect(out).must_match exp_out
    expect(err).must_match exp_err
  end

  it "fails" do
    exp_out = /FAILED: 'false'/
    assert_io_matches(exp_out, "") do
      Jobrnr::Application.new(%w[test/fixtures/job_exit_status/fail.rb -d fail]).run
    end
  end

  it "passes" do
    exp_out = /PASSED: 'true'/
    assert_io_matches(exp_out, "") do
      Jobrnr::Application.new(%w[test/fixtures/job_exit_status/pass.rb -d pass]).run
    end
  end

  it "passes and fails" do
    out, err = capture_subprocess_io do
      Jobrnr::Application.new(%w[test/fixtures/job_exit_status/pass_and_fail.rb -j1 -d pass_and_fail]).run
    end

    expect(out).must_match(/PASSED: 'job 0' slot:recycled exitcode:0/)
    expect(out).must_match(/FAILED: 'job 1' slot:0 exitcode:1/)
    expect(out).must_match(/FAILED: 'job 42' slot:1 exitcode:42/)
    expect(out).must_match(%r{FAILED: 'command_not_found arg' slot:2 exitcode:n/a})
    expect(err).must_equal ""

    command_not_found_output = File.read("pass_and_fail/2")
    expect(command_not_found_output).must_equal("ERROR: failed to spawn command 'command_not_found arg' " \
                                                "for job 'command_not_found': No such file or directory " \
                                                "- command_not_found")
  end
end
