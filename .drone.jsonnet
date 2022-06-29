local name = "plex";
local browser = "firefox";

local build(arch, testUI) = [{
    kind: "pipeline",
    type: "docker",
    name: arch,
    platform: {
        os: "linux",
        arch: arch
    },
    steps: [
        {
            name: "version",
            image: "debian:buster-slim",
            commands: [
                "echo $DRONE_BUILD_NUMBER > version",
                "echo device.com > domain"
            ]
        },
       {
            name: "build python",
            image: "debian:buster-slim",
            commands: [
                "./python/build.sh"
            ],
            volumes: [
                {
                    name: "docker",
                    path: "/usr/bin/docker"
                },
                {
                    name: "docker.sock",
                    path: "/var/run/docker.sock"
                }
            ]
        },
        {
            name: "build",
            image: "debian:buster-slim",
            commands: [
                "VERSION=$(cat version)",
                "./build.sh " + name + " $VERSION"
            ]
        },
        {
            name: "test-integration",
            image: "python:3.8-slim-buster",
            commands: [
              "apt-get update && apt-get install -y sshpass openssh-client netcat rustc file",
              "APP_ARCHIVE_PATH=$(realpath $(cat package.name))",
              "DOMAIN=$(cat domain)",
              "cd integration",
              "pip install -r requirements.txt",
              "py.test -x -s verify.py --domain=$DOMAIN --app-archive-path=$APP_ARCHIVE_PATH --device-host=device --app=" + name
            ]
        }] + ( if testUI then [
        {
            name: "test-ui-desktop",
            image: "python:3.8-slim-buster",
            commands: [
              "apt-get update && apt-get install -y sshpass openssh-client",
              "DOMAIN=$(cat domain)",
              "cd integration",
              "pip install -r requirements.txt",
              "py.test -x -s test-ui.py --ui-mode=desktop --domain=$DOMAIN --device-host=device --app=" + name + " --browser=" + browser,
            ],
            volumes: [{
                name: "shm",
                path: "/dev/shm"
            }]
        },
        {
            name: "test-ui-mobile",
            image: "python:3.8-slim-buster",
            commands: [
              "apt-get update && apt-get install -y sshpass openssh-client",
              "DOMAIN=$(cat domain)",
              "cd integration",
              "pip install -r requirements.txt",
              "py.test -x -s test-ui.py --ui-mode=mobile --domain=$DOMAIN --device-host=device --app=" + name + " --browser=" + browser,
            ],
            volumes: [{
                name: "shm",
                path: "/dev/shm"
            }]
        }] else [] ) + [
        {
            name: "upload",
        image: "debian:buster-slim",
        environment: {
            AWS_ACCESS_KEY_ID: {
                from_secret: "AWS_ACCESS_KEY_ID"
            },
            AWS_SECRET_ACCESS_KEY: {
                from_secret: "AWS_SECRET_ACCESS_KEY"
            }
        },
        commands: [
          "PACKAGE=$(cat package.name)",
          "apt update && apt install -y wget",
          "wget https://github.com/syncloud/snapd/releases/download/1/syncloud-release-" + arch,
          "chmod +x syncloud-release-*",
          "./syncloud-release-* publish -f $PACKAGE -b $DRONE_BRANCH"
         ],
        when: {
            branch: ["stable", "master"]
        },
        {
            name: "artifact",
            image: "appleboy/drone-scp:1.6.2",
            settings: {
                host: {
                    from_secret: "artifact_host"
                },
                username: "artifact",
                key: {
                    from_secret: "artifact_key"
                },
                timeout: "2m",
                command_timeout: "2m",
                target: "/home/artifact/repo/" + name + "/${DRONE_BUILD_NUMBER}-" + arch,
                source: "artifact/*",
		             strip_components: 1
            },
            when: {
              status: [ "failure", "success" ],
              event: [ "push" ]
            }
        }
    ],
     trigger: {
       event: [
         "push",
         "pull_request"
       ]
     },
    services: [
        {
            name: "device.com",
            image: "syncloud/platform-buster-" + arch + ":21.10",
            privileged: true,
            volumes: [
                {
                    name: "dbus",
                    path: "/var/run/dbus"
                },
                {
                    name: "dev",
                    path: "/dev"
                }
            ]
        }
    ] + if testUI then [{
            name: "selenium",
            image: "selenium/standalone-" + browser + ":4.0.0-beta-3-prerelease-20210402",
            volumes: [{
                name: "shm",
                path: "/dev/shm"
            }]
        }] else [],
    volumes: [
        {
            name: "dbus",
            host: {
                path: "/var/run/dbus"
            }
        },
        {
            name: "dev",
            host: {
                path: "/dev"
            }
        },
        {
            name: "shm",
            temp: {}
        },
        {
            name: "docker",
            host: {
                path: "/usr/bin/docker"
            }
        },
        {
            name: "docker.sock",
            host: {
                path: "/var/run/docker.sock"
            }
        }
    ]
},
 {
      kind: "pipeline",
      type: "docker",
      name: "promote-" + arch,
      platform: {
          os: "linux",
          arch: arch
      },
      steps: [
      {
              name: "promote",
              image: "debian:buster-slim",
              environment: {
                  AWS_ACCESS_KEY_ID: {
                      from_secret: "AWS_ACCESS_KEY_ID"
                  },
                  AWS_SECRET_ACCESS_KEY: {
                      from_secret: "AWS_SECRET_ACCESS_KEY"
                  }
              },
              commands: [
                "apt update && apt install -y wget",
                "wget https://github.com/syncloud/snapd/releases/download/1/syncloud-release-" + arch + " -O release --progress=dot:giga",
                "chmod +x release",
                "./release promote -n " + name + " -a $(dpkg --print-architecture)"
              ]
        }
       ],
       trigger: {
        event: [
          "promote"
        ]
      }
  }];

build("arm", false) +
build("amd64", true) +
build("arm64", false)
