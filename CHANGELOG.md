# Changelog

All notable changes to this project are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses [SemVer](https://semver.org/).

## [Unreleased]

### Added

- Addon skeleton: TOC for WoW Forever (Interface 16001), AceDB saved variables, `/wd` slash command.
- Step tracking: walking on foot outdoors counts steps; mounted, taxi, vehicle, dead, instance and teleport moves are ignored.
- Pack earning: one counter per character; each pack goes to the zone where most of its steps were walked.
- `/wd status` shows steps walked, progress to the next pack and unopened packs.
- Developer `/wd probe` command that reports which position, map and movement APIs work on the client.
