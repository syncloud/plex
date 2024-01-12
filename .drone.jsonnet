local name = "plex";
local browser = "firefox";
local selenium = "4.0.0-beta-3-prerelease-20210402";
local platform = "22.01";
local plex = "1.32.7.7621-871adbd44";
local deployer = "https://github.com/syncloud/store/releases/download/4/syncloud-release";

local build(arch, testUI, dind) = [{
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
                "echo $DRONE_BUILD_NUMBER > version"
            ]
        },
        {
               name: "build",
               image: "debian:buster-slim",
               commands: [
                   "./build.sh " + plex
               ]
        },
	    {
            name: "build python",
            image: "docker:" + dind,
            commands: [
                "./python/build.sh"
            ],
            volumes: [
                {
                    name: "dockersock",
                    path: "/var/run"
                }
            ]
        },
       {
            name: "package",
            image: "debian:buster-slim",
            commands: [
               "VERSION=$(cat version)",
               "./package.sh " + name + " $VERSION "
            ]
        },
        {
            name: "test-integration",
            image: "python:3.8-slim-buster",
            commands: [
              "APP_ARCHIVE_PATH=$(realpath $(cat package.name))",
              "cd integration",
              "./deps.sh",
              "py.test -x -s verify.py --app-archive-path=$APP_ARCHIVE_PATH --device-host=device --app=" + name
            ]
        }] + ( if testUI then [
        {
            name: "test-ui-desktop",
            image: "python:3.8-slim-buster",
            commands: [
              "cd integration",
              "./deps.sh",
              "py.test -x -s test-ui.py --ui-mode=desktop --device-host=device --app=" + name + " --browser=" + browser,
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
              "cd integration",
              "./deps.sh",
              "py.test -x -s test-ui.py --ui-mode=mobile --device-host=device --app=" + name + " --browser=" + browser,
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
            },
            SYNCLOUD_TOKEN: {
                from_secret: "SYNCLOUD_TOKEN"
            }
        },
        commands: [
          "PACKAGE=$(cat package.name)",
          "apt update && apt install -y wget",
          "wget " + deployer + "-" + arch + " -O release --progress=dot:giga",
          "chmod +x release",
          "./release publish -f $PACKAGE -b $DRONE_BRANCH"
         ],
        when: {
            branch: ["stable", "master"],
	    event: ["push"]
        }
	},
        {
            name: "artifact",
            image: "appleboy/drone-scp:1.6.4",
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
            name: "docker",
            image: "docker:" + dind,
            privileged: true,
            volumes: [
                {
                    name: "dockersock",
                    path: "/var/run"
                }
            ]
        },
        {
            name: "device.com",
            image: "syncloud/platform-buster-" + arch + ":" + platform,
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
            image: "selenium/standalone-" + browser + ":" + selenium,
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
            name: "dockersock",
            temp: {}
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
                 "wget " + deployer + "-" + arch + " -O release --progress=dot:giga",
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

build("amd64", true, "20.10.21-dind") +
build("arm64", false, "19.03.8-dind") +
build("arm", false, "19.03.8-dind")
