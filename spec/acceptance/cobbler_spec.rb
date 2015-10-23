require 'spec_helper_acceptance'

describe 'cobbler class' do

  describe 'without parameters' do
    it 'should idempotently run' do
      pp = <<-EOS
        class { cobbler: }
      EOS

      apply_on_all_hosts(pp)
    end
  end
end
