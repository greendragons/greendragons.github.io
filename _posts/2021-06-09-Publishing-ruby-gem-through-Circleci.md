---
layout: post
title: Publishing ruby gem through CircleCi
tags: ruby gems circleci
---

### Overview
In this post I'll cover writing simple ruby gem and publishing through CircleCi.
Rather than focusing on best practices or patterns for writing gem, I'll focus on having quick and dirty
end to end system for releasing a gem.

### Table of Contents
1. [Writing a gem](###Writing-a-gem)
1. [Adding gemspec file](###Adding-gemspec-file)
2. [My Second Title](#markdown-header-my-second-title)

### Accounts Setup
In order to follow the tutorial please ensure to:
1. Create a github repo for this project, and name it whatever you want.
This repository will be used to maintain our gem code.

2. Create a CircleCi account and add this repository, it will be asking to add config.yml file,
but for now you can skip it as we will be adding it manually later.

### Writing a gem
Make sure to select a unique name for the gem, for example `worldhello` also have same name `.rb` file,
as users will use it as `require worldhello`.
For uniqueness one can suffix with username `worldhello_<username>`

Create directory structure as:

```
ruby-gems-publish-example/
└── lib
    └── worldhello.rb
```

Put some content in `worldhello.rb` file

```
class WorldHello
  def self.hello
    "Hello World!"
  end
end
```

### Adding gemspec file
Gemspec file contains gem metadata like what is in the gem, who created it, and the version. This information is
displayed on the rubygems website for that gem.

Attributes of gemspec file are pretty self explanatory. Some attributes are required and others are recommended or optional.
For more details about attributes in gemspec file refer : [link](https://guides.rubygems.org/specification-reference/)

Let us add a file `worldhello.gemspec`

```
ruby-gems-publish-example/
├── lib
│   └── worldhello.rb
└── worldhello.gemspec
```

Contents of `worldhello.gemspec`

```
Gem::Specification.new do |s|
  s.name        = 'worldhello'
  s.version     = '0.0.1'
  s.summary     = "Hello World Gem!"
  s.description = "A simple hello world gem"
  s.authors     = ["<author name>"]
  s.files       = ["lib/worldhello.rb"]
  s.homepage    =
    'https://rubygems.org/gems/worldhello'
  s.license       = 'MIT'
end
```

### Building gem locally
Gemspec file is used to build the gem.
```
> gem build worldhello.gemspec
```

You will find worldhello-0.0.1.gem file created in the directory.
```
ruby-gems-publish-example/
├── lib
│   └── worldhello.rb
├── worldhello-0.0.1.gem
└── worldhello.gemspec
```

### Adding Tests
Add files `Rakefile` and `test/test_worldhello.rb`
```
ruby-gems-publish-example/
├── Rakefile
├── lib
│   └── worldhello.rb
├── test
│   └── test_worldhello.rb
├── worldhello-0.0.1.gem
└── worldhello.gemspec
```

Contents of Rakefile
```
require 'rake/testtask'

Rake::TestTask.new do |t|
    t.libs << 'test'
end

desc "Run tests"
task :default => :test
```

Contents of test file `test_worldhello.rb`
```
require 'minitest/autorun'
require 'worldhello'

class WorldHelloTest < Minitest::Test
    def test_hello_world
        assert_equal "Hello World!",
            WorldHello.hello
    end
end
```

Running tests
```
> rake test
```

### Setting up CircleCi config
First step is to create account with CircleCi if you don't have one and then add project in the CircleCi account.
Now on your local machine add file `.circleci/config.yml`
```
version: 2

jobs:
  build:
    machine: true
    steps:
      - checkout
      - run:
          name: Build gem
          command: gem build worldhello.gemspec
      - run:
          name: Install locally
          command: gem install --development *.gem
      - run:
          name: Run Tests
          command: rake test
```
This is simple CircleCi build config file, we can run all steps in just one job.

### Publishing gem with API key
In order to publish our gem, we need to have an account with rubygems.org and create a private API key
with permission to push gems.
For example private API key looks something like:
```
rubygems_4dc5a0061ebf5b500088933f56cec596ade0fa042a43413a
```

Add this API key in CircleCi environment variable

![Adding API Key](/assets/2021-06-09-Publishing-ruby-gem-through-Circleci/images/adding_api_key.png)

```
Name: RUBY_GEM_API_KEY
Value: rubygems_4dc5a0061ebf5b500088933f56cec596ade0fa042a43413a
```

`gem push <gemfile>` expects API key in ~/.gem/credentials file.
We add one more step in `config.yml` file
```
version: 2

jobs:
  build:
    machine: true
    steps:
      - checkout
      - run:
          name: Build gem
          command: gem build worldhello.gemspec
      - run:
          name: Install locally
          command: gem install --development *.gem
      - run:
          name: Run Tests
          command: rake test
      - run:
          name: Publish Gem
          command: |
            mkdir -p ~/.gem
            echo -e "---\r\n:rubygems_api_key: $RUBY_GEM_API_KEY" > ~/.gem/credentials
            chmod 0600 ~/.gem/credentials
            gem push worldhello*.gem
```

Now when CircleCi build triggers, you'll be able to see your gem published

### Versioning Gem
In this example we have considered a simple gem which just prints `Hello World!`, but what if
we had something more meaningful then we would want to have an automated way of releasing our gem
with updated version.

Ideally we would like to have new version release with every merge to master branch.
To achieve this we should maintain current version information and automatically update this version
with every merge to master and use this updated version in gemspec file.
But in this tutorial I won't be covering auto-incrementing version, for now we can manually
update versions in `version.rb` file.

Add a file version.rb inside `lib` directory, with initial version defined.
```
module WorldHello
    VERSION = '0.0.1'
end
```

```
ruby-gems-publish-example/
├── Rakefile
├── lib
│   ├── version.rb
│   └── worldhello.rb
├── test
│   └── test_worldhello.rb
├── worldhello-0.0.1.gem
└── worldhello.gemspec
```

Refer this version constant in gemspec.

```
require_relative('lib/version.rb')

Gem::Specification.new do |s|
  s.name        = 'worldhello'
  s.version     = WorldHello::VERSION
  s.summary     = "Hello World Gem!"
  s.description = "A simple hello world gem"
  s.authors     = ["<author name>"]
  s.files       = ["lib/worldhello.rb"]
  s.homepage    =
    'https://rubygems.org/gems/worldhello'
  s.license       = 'MIT'
end
```

Just commit and push the changes and our gem will be published.
Check your rubygems account it will list the authored gem:

![Published Gem Image](/assets/2021-06-09-Publishing-ruby-gem-through-Circleci/images/published_gem.png)
