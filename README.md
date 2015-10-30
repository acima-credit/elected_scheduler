# ElectedScheduler - A ruby distributed cron-like scheduler that only runs jobs on leader processes.

> Schedule your jobs at cron-like times (seconds included) and run the jobs only if the process is the current leader.
> 
> This gem depends on the [elected](https://github.com/simple-finance/elected) ruby gem to select a leader and 
> keep it for a set of time.  

ElectedScheduler is a Spanglish-fluent gem so expect Spanish and English names all over. Pardon my French!

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'elected_scheduler'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install elected_scheduler

## Documentation

[RubyDoc](http://www.rubydoc.info/gems/elected_scheduler/frames)

## Usage example

```ruby
  # Let's open up a console and get the ball rolling.
  $> bin/console
  
  # Config your redis urls or use the default REDIS_URL environment variable by default.
  Elected.redis_urls = ['redis://localhost:6379', 'redis://someotherhost:6379']
  
  # Create a poller object that will keep your job definitions and distributed lock
  # You will need to choose a key (common between similar processes) 
  # and a timeout (in ms) to select a new leader.
  poller = Elected::Scheduler::Poller.new 'some_key', 30_000
  
  # Let's create and add our first job
  job1 = Elected::Scheduler::Job.new('j1')
  job1.run { puts '>> job #1' }
  job1.at seconds: [0,2]
  poller << job1
  
  # Let's create and add our second job
  job2 = Elected::Scheduler::Job.new('j1'){ puts '>> job #2' }.add(seconds: [1,2])
  poller << job2
   
  # Now we'll tell the poller to start doing it's magic! 
  # after starting we'll get back control of the console
  poller.start!
  
  # Now in the background the poller will become the leader
  # and run our jobs at the right times and we'll see some lines get printer over time
  >> job #1
  >> job #2
  >> job #1
  >> job #2
  ...
  
  # After some time we can stop the poller from running.
  poller.stop
```

To truly see the effect you might want to run these examples in two or more consoles so you can 
see how it only executes the jobs on a process at a time. 
After the timeout hits then the first process to request leader access will become the leader. 
This way your jobs will get executed only once no matter how many servers you run them on.

## Run tests

Make sure you have at least 1 redis instances up.

    $ rake rspec

## Disclaimer

The hard work of securing a distributed lock is all done through the great 
[redlock](https://github.com/leandromoreira/redlock-rb) gem. 
Thanks to [Leandro Moreira](https://github.com/leandromoreira) for his hard work.
This code, thanks to Redlock, implements an algorithm which is currently a proposal, it was not formally analyzed. 
Make sure to understand how it works before using it in your production environments. 
You can see discussion about this approach at 
[reddit](http://www.reddit.com/r/programming/comments/2nt0nq/distributed_lock_using_redis_implemented_in_ruby/).

In general you need to be careful if the leader process dies and does not release on exit then until the timeout 
hits no other process will run the scheduled jobs. Setting the right timeout and having enough processes running 
will mitigate the possibilities of that scenario becoming a major problem.   

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. 
You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update 
the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for 
the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/simple-finance/elected_scheduler. 
This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere 
to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

