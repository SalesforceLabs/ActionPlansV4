# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased](https://github.com/dschach/ActionPlansV4/compare/4.2.1...HEAD)

### Merged

- build(deps-dev): bump lint-staged from 13.1.2 to 13.2.0 [`#7`](https://github.com/dschach/ActionPlansV4/pull/7)
- build(deps-dev): bump eslint from 8.35.0 to 8.36.0 [`#6`](https://github.com/dschach/ActionPlansV4/pull/6)
- build(deps-dev): bump eslint from 8.34.0 to 8.35.0 [`#4`](https://github.com/dschach/ActionPlansV4/pull/4)
- feat(tests): update tests (assertions, messages) [`#3`](https://github.com/dschach/ActionPlansV4/pull/3)
- feat: update API to 57.0 [`#1`](https://github.com/dschach/ActionPlansV4/pull/1)
- Bump github/codeql-action from 1 to 2 [`#59`](https://github.com/dschach/ActionPlansV4/pull/59)
- Fix assigned to field [`#60`](https://github.com/dschach/ActionPlansV4/pull/60)
- Archived flag, dependent task fixes, SOQL optimization [`#58`](https://github.com/dschach/ActionPlansV4/pull/58)
- Cosmetic rearrangements, apexdoc [`#55`](https://github.com/dschach/ActionPlansV4/pull/55)
- 4.3.0 Queues, Child Objects [`#53`](https://github.com/dschach/ActionPlansV4/pull/53)
- Version 4.3.0 pt 2 [`#47`](https://github.com/dschach/ActionPlansV4/pull/47)
- Version 4.3.0 [`#44`](https://github.com/dschach/ActionPlansV4/pull/44)
- Codecov to v3 [`#41`](https://github.com/dschach/ActionPlansV4/pull/41)

### Commits

- build(npm): update package dependencies [`e40b10a`](https://github.com/dschach/ActionPlansV4/commit/e40b10a0129cc415527a4876ae6bf2f5893369b5)
- lightning lookup w/o API v1 [`e8dac8e`](https://github.com/dschach/ActionPlansV4/commit/e8dac8e7d0ab626fbb18bce7587a092b80a646cb)
- docs(ApexDox): rerun ApexDox [`bc720e2`](https://github.com/dschach/ActionPlansV4/commit/bc720e21f85ee44c9fbecd2ddc9c5b12523b24a4)
- docs(ApexDox): include Installation & Changelog [`4910af9`](https://github.com/dschach/ActionPlansV4/commit/4910af9d9714cb57ce662e0057c00a97a5897e3f)
- feat(docs): ApexDox version upgrade [`178e1ce`](https://github.com/dschach/ActionPlansV4/commit/178e1ce30ff4bcf6505429fcf809e7ec742f08c3)
- build: move tests folder into classes [`99d78d5`](https://github.com/dschach/ActionPlansV4/commit/99d78d5a3302b6881a99d01c370c3c6e7cc523f4)
- Tests use Assert class [`59d6ef2`](https://github.com/dschach/ActionPlansV4/commit/59d6ef2150bf29d68d79014be463923e83e39e35)
- build(sfdx): change sfdx to sf commands [`994b3f2`](https://github.com/dschach/ActionPlansV4/commit/994b3f241cd5e5ab81955571bc6ad9ab839d4c38)
- revert(API): use 56.0 to avoid GVS bug [`6eb588a`](https://github.com/dschach/ActionPlansV4/commit/6eb588a4439d1787e613995f4dbe6e9c808df7e1)
- feat: finish Professional Edition template lookup [`415fdcf`](https://github.com/dschach/ActionPlansV4/commit/415fdcfc8f784af02a6b5c22a25e38e52dffce93)
- docs: update CanTheUser comments [`22ea89c`](https://github.com/dschach/ActionPlansV4/commit/22ea89c57e2a545cb2443e4f8f9c13aabff9adb9)
- API 56.0 [`4303659`](https://github.com/dschach/ActionPlansV4/commit/43036599390a3fec5617f9b39986b030382960cb)
- fix: page redirect on template from object [`70f43ba`](https://github.com/dschach/ActionPlansV4/commit/70f43ba924930914499b9ad3cdc8d5dc0c9796be)
- feat(sfdx): update sfdx to sf [`f360666`](https://github.com/dschach/ActionPlansV4/commit/f36066624737f029454d9eed5d28a81c6309f24e)
- fix: remove unnecessary jsencode [`96070b1`](https://github.com/dschach/ActionPlansV4/commit/96070b187dda50d7cfe21a897868c690976b750c)
- fix: redirect on template choice for records [`8bf011b`](https://github.com/dschach/ActionPlansV4/commit/8bf011b5eb9e965f0f6016233b81a1aa239edc25)
- Deploy rules & scripts [`5b80488`](https://github.com/dschach/ActionPlansV4/commit/5b80488663d56cc79ba90ffcf6a727c44d1a588a)
- APTemplate lookup actions [`d34eaaf`](https://github.com/dschach/ActionPlansV4/commit/d34eaaf3d3c6958bb5115215259b81a491dfe266)
- fix(docs): update ApexDox [`e8481e8`](https://github.com/dschach/ActionPlansV4/commit/e8481e82bce1c97f8b44a5e47178f8ca815c8824)
- ci(codeQL): delete codeQL d/t IP address [`fa066cf`](https://github.com/dschach/ActionPlansV4/commit/fa066cfc4ddeb5017957abe873bfc8ad22f155f6)
- dependabot auto-merge [`b5e5d4f`](https://github.com/dschach/ActionPlansV4/commit/b5e5d4f4a1e1e2db2f9ffd8e09b4e7ffd67488cf)
- docs: cleanup code, document variables [`f27e8dc`](https://github.com/dschach/ActionPlansV4/commit/f27e8dccc8c4977a859e70a939b6c34a624729e8)
- feat: Update tests to use Assert class [`2069b97`](https://github.com/dschach/ActionPlansV4/commit/2069b97f7a65a68966efb2c49867a05a1f587719)
- fix(build): Update plugin dependencies [`4bf530c`](https://github.com/dschach/ActionPlansV4/commit/4bf530c6e5f1b60dcef86408e3acffc2376993dd)
- Update scratch org definition files [`851171c`](https://github.com/dschach/ActionPlansV4/commit/851171c6b2120b3e421909bb627fc2e454a2d4f7)
- chore: Scratch org shape updates [`fbe390e`](https://github.com/dschach/ActionPlansV4/commit/fbe390e7745f2d508a221d900d98f47feda0f061)
- docs(Apex): test comments [`5056ebc`](https://github.com/dschach/ActionPlansV4/commit/5056ebc9d8665fc70f4bf6d566a160c86251d5b6)
- ci: update PR sfdx to sf, npm installation [`77fa739`](https://github.com/dschach/ActionPlansV4/commit/77fa73957caf481dd5081a258d6b5a9e3c72decc)
- build(changelog): instructions & tag prefix [`0ae955b`](https://github.com/dschach/ActionPlansV4/commit/0ae955b8fc5056351c4c1f4ad66690fb56f53ea5)
- Beta 4.3.0-9 [`d4b477c`](https://github.com/dschach/ActionPlansV4/commit/d4b477c46a7487fd6ff07784b91ac99979e8bc71)
- fix(sfdx): sf apex test correct config [`6a030e4`](https://github.com/dschach/ActionPlansV4/commit/6a030e43da9aaff5bd9780803996f9fe63736cf1)
- feat: sfdx-scanner config [`42c6889`](https://github.com/dschach/ActionPlansV4/commit/42c6889df390a41195629f11d8453d429d64e769)
- docs(README): add image descriptions [`2b9f999`](https://github.com/dschach/ActionPlansV4/commit/2b9f999452002ff43152102cbb85348dbd0e1d7e)
- Dependabot alerts [`dea7b92`](https://github.com/dschach/ActionPlansV4/commit/dea7b929eaf6d555762795865fcfd2d12181d403)
- Bug Report Template [`acfda0a`](https://github.com/dschach/ActionPlansV4/commit/acfda0ae35984f3b48103be7fea9cce6411d2791)
- Bug template [`516f70c`](https://github.com/dschach/ActionPlansV4/commit/516f70c863549733964884939ef6b2cd77ca46d1)
- build(pmd): remove updatepmd [`0ef9783`](https://github.com/dschach/ActionPlansV4/commit/0ef9783b4c94c86ba07429ca36aa1abb650d9c19)
- feat(scripts): update latest jQuery [`992988e`](https://github.com/dschach/ActionPlansV4/commit/992988e433f53d6cf7099902d2b9ab79ba86503e)
- fix(lookup): escape=false for record name [`5fae8c0`](https://github.com/dschach/ActionPlansV4/commit/5fae8c09373dc86c9cc3ae30ad6ac7d27bb47770)
- Changelog [`6516aa9`](https://github.com/dschach/ActionPlansV4/commit/6516aa97d738d0742cf552c8cd608d5761c3ae09)

## [4.2.1](https://github.com/dschach/ActionPlansV4/compare/4.2.0...4.2.1) - 2022-05-25

### Merged

- Version 4.2.1 [`#37`](https://github.com/dschach/ActionPlansV4/pull/37)
- Namespace to sample code [`#36`](https://github.com/dschach/ActionPlansV4/pull/36)
- v4.2.0 [`#30`](https://github.com/dschach/ActionPlansV4/pull/30)

### Fixed

- Version 4.2.1 (#37) [`#35`](https://github.com/dschach/ActionPlansV4/issues/35) [`#34`](https://github.com/dschach/ActionPlansV4/issues/34)
- Namespace to sample code (#36) [`#35`](https://github.com/dschach/ActionPlansV4/issues/35)

### Commits

- Correct Apex global method syntax [`eaee330`](https://github.com/dschach/ActionPlansV4/commit/eaee3301c8502edcf27a99c0955b44ce063ca0d0)
- ApexDox update [`da133ff`](https://github.com/dschach/ActionPlansV4/commit/da133ffed6f45bd0c4ebb8cf498a0223ed5d02d0)
- Promote v2.4.0.7 [`70849b9`](https://github.com/dschach/ActionPlansV4/commit/70849b9570742c112054b161973d9584cf0cc5a1)
- Changelog, packaging workflow [`5b77ddb`](https://github.com/dschach/ActionPlansV4/commit/5b77ddba5da486f283825e3304d1be5b8dce298c)
- Packaging workflow [`9107fd9`](https://github.com/dschach/ActionPlansV4/commit/9107fd99c3f3f36c4d070960412837f98b20af88)

## [4.2.0](https://github.com/dschach/ActionPlansV4/compare/4.1.0...4.2.0) - 2022-04-01

### Merged

- Specify Action Plan Name in Invocable Apex [`#27`](https://github.com/dschach/ActionPlansV4/pull/27)
- Prettier, JS fixing [`#26`](https://github.com/dschach/ActionPlansV4/pull/26)
- Highlight.js to 11.5 [`#25`](https://github.com/dschach/ActionPlansV4/pull/25)
- Add changelog [`#24`](https://github.com/dschach/ActionPlansV4/pull/24)
- Bump minimist from 1.2.5 to 1.2.6 [`#23`](https://github.com/dschach/ActionPlansV4/pull/23)
- Upgrading Instructions [`#22`](https://github.com/dschach/ActionPlansV4/pull/22)
- Add Codecov [`#21`](https://github.com/dschach/ActionPlansV4/pull/21)

### Commits

- ApexDox remove unused modifiers [`3b321db`](https://github.com/dschach/ActionPlansV4/commit/3b321dbd7d72eb7214e6533d5f24da105c76e6d5)
- Create codeql-analysis.yml [`2822bc5`](https://github.com/dschach/ActionPlansV4/commit/2822bc510e267148e3800d3241414893d0b0d92e)
- Highlight inline code security update [`57662e7`](https://github.com/dschach/ActionPlansV4/commit/57662e75737928c6362853cbaec4bafd199b6f25)
- Pull Request workflow update [`2c84f4d`](https://github.com/dschach/ActionPlansV4/commit/2c84f4dfd17062ddf4d08ff04d773f2a3d3f3d4b)
- Update and rename CONTRIBUTION.md to CONTRIBUTING.md [`cb7f3c1`](https://github.com/dschach/ActionPlansV4/commit/cb7f3c1c1ceea838050e6afe65eb89b556ab1d38)
- update Prettierignore [`37aeafa`](https://github.com/dschach/ActionPlansV4/commit/37aeafa8c42bdb08ba167eb3e82898ba16a2abf1)
- Add link to Apex documentation [`96f9cde`](https://github.com/dschach/ActionPlansV4/commit/96f9cde62ce62e1e568d609838250653c35ec7cb)
- Sample template update [`4c957ca`](https://github.com/dschach/ActionPlansV4/commit/4c957ca63a3a93f0378d95bba563ad86402b990d)
- Update CONTRIBUTING.md [`9e3b175`](https://github.com/dschach/ActionPlansV4/commit/9e3b175772293fdebb6ae0a17e574d0d3f8cbc33)
- Add AppExchange listing to README [`760dfc9`](https://github.com/dschach/ActionPlansV4/commit/760dfc91b97ed879aeec8d0ca1228cc46f4ad154)
- Sample flow update [`397b763`](https://github.com/dschach/ActionPlansV4/commit/397b76342026c63507cacc97a147a43287cc02ee)

## [4.1.0](https://github.com/dschach/ActionPlansV4/compare/4.0.0-9...4.1.0) - 2022-03-17

### Merged

- Release Ready [`#19`](https://github.com/dschach/ActionPlansV4/pull/19)
- Pre-Release (beta15) [`#18`](https://github.com/dschach/ActionPlansV4/pull/18)
- Pre-Commit ApexDox cleanup [`#16`](https://github.com/dschach/ActionPlansV4/pull/16)
- Scripts, Cleanup, New Build [`#15`](https://github.com/dschach/ActionPlansV4/pull/15)

### Commits

- Update issue templates [`e2be869`](https://github.com/dschach/ActionPlansV4/commit/e2be869204599eed28a990fffa43837c3ea3b5be)
- Import file language [`5be81e1`](https://github.com/dschach/ActionPlansV4/commit/5be81e17568678735f289c05a080589a5e63bfab)
- Start package versioning via release [`afd008a`](https://github.com/dschach/ActionPlansV4/commit/afd008adb2f753dbe5742e9027ea70121b169b9d)
- ISV toolkit md exclusion [`022c65a`](https://github.com/dschach/ActionPlansV4/commit/022c65a67eba69f1c220e006a70ca6ececad03b9)
- AppExchange link [`31f2e02`](https://github.com/dschach/ActionPlansV4/commit/31f2e028c89548c1cea2677693f0dabc277d9ae1)
- Apex highlighting [`0609b37`](https://github.com/dschach/ActionPlansV4/commit/0609b3733a8f5066037768cb1ac6145357d80b6f)

## 4.0.0-9 - 2022-02-23

### Merged

- AP Task AssignedTo field cleanup [`#14`](https://github.com/dschach/ActionPlansV4/pull/14)
- Managed vs Unmanaged Project Config [`#13`](https://github.com/dschach/ActionPlansV4/pull/13)
- Permissions Updates [`#12`](https://github.com/dschach/ActionPlansV4/pull/12)
- Remove tests from ApexDox [`#10`](https://github.com/dschach/ActionPlansV4/pull/10)
- Security, code coverage, Print page, Spring 22! [`#7`](https://github.com/dschach/ActionPlansV4/pull/7)
- Code and documentation cleanup [`#6`](https://github.com/dschach/ActionPlansV4/pull/6)
- PMD-suggested cleanup [`#5`](https://github.com/dschach/ActionPlansV4/pull/5)
- Rename Template Task [`#4`](https://github.com/dschach/ActionPlansV4/pull/4)
- Version 4.0.0.7 [`#3`](https://github.com/dschach/ActionPlansV4/pull/3)
- Code comment cleanup [`#2`](https://github.com/dschach/ActionPlansV4/pull/2)
- ApexDocs, Project Files, PMD rules [`#1`](https://github.com/dschach/ActionPlansV4/pull/1)

### Commits

- Documentation with ApexDox [`236c66b`](https://github.com/dschach/ActionPlansV4/commit/236c66b82c79062836ee059917842bf25d42ac39)
- Iniital commit, updated for namespace [`f4d7498`](https://github.com/dschach/ActionPlansV4/commit/f4d74984e51128788ee329a03764b521b9515b68)
- migrate to new sfdx-falcon directory [`0cde1dc`](https://github.com/dschach/ActionPlansV4/commit/0cde1dc403755cdf37dd7bd9e31155fce65277df)
- move to sfdx-source falcon directory structure [`2edf46d`](https://github.com/dschach/ActionPlansV4/commit/2edf46d356f0e2c029159c2818d874a3a6192620)
- package files [`16c26fc`](https://github.com/dschach/ActionPlansV4/commit/16c26fc10e24f9331c16973cca7c9ed0b2ce753c)
- Prettier first pass [`9467195`](https://github.com/dschach/ActionPlansV4/commit/94671959b397325f040c898a1e01173eafe284cc)
- ApexDox [`1fc534b`](https://github.com/dschach/ActionPlansV4/commit/1fc534ba2f94fd715972537598f5146760866aed)
- ApexDox [`48589f7`](https://github.com/dschach/ActionPlansV4/commit/48589f7481ed8bb5baa565def244c4029f0dd0d2)
- First commit - ReadMe & Installation [`406674a`](https://github.com/dschach/ActionPlansV4/commit/406674a13cb7b5c68db946ff8038c9df16e62d63)
- package files [`45278ca`](https://github.com/dschach/ActionPlansV4/commit/45278caa0d7f0d97141c5950fa0be8831e7c1c95)
- Install/update prettier [`62fd10a`](https://github.com/dschach/ActionPlansV4/commit/62fd10a3fad113f2ee39a0e6dc642d1c84dc4dfe)
- Exclude unmanaged and unpackaged metadata [`32bcb00`](https://github.com/dschach/ActionPlansV4/commit/32bcb0020732b1fa6aba8c9776fe1b0ac3d2b474)
- Unmanaged metadata for managed installation [`ed24492`](https://github.com/dschach/ActionPlansV4/commit/ed244927e79d18b8bb5085364c1481e92d97e6b4)
- Remove non-dev org actions [`29208d8`](https://github.com/dschach/ActionPlansV4/commit/29208d835bf4edd3952f981db85e30fbd21b6ae3)
- Install script for custom setting [`11e6b5d`](https://github.com/dschach/ActionPlansV4/commit/11e6b5d9e07f01a5a60521faa7a9632618fbfd66)
- Update for EE orgs [`83e459d`](https://github.com/dschach/ActionPlansV4/commit/83e459d805cfa59c2f381f53949ddcddeb7d9bd0)
- Fix lookup for portal users, custom setting DML [`dc6ea13`](https://github.com/dschach/ActionPlansV4/commit/dc6ea13871cf95df4d3d76f931edfdef373d04a1)
- Support unmanaged metadata [`f8681e8`](https://github.com/dschach/ActionPlansV4/commit/f8681e880dfae3eec6b2a5427b6df65a9141224b)
- Add gitignore [`433c579`](https://github.com/dschach/ActionPlansV4/commit/433c57938dd801ad1078cfc58bb2aa7b3b01fba8)
- Documentation and support files [`9993d83`](https://github.com/dschach/ActionPlansV4/commit/9993d83093101ab05f5057b7f726350065c0c4f6)
- ApexDox [`c5c3144`](https://github.com/dschach/ActionPlansV4/commit/c5c314412d1f42d5138b9575c317333ecc18e83a)
- Simplify Account layout [`536459a`](https://github.com/dschach/ActionPlansV4/commit/536459a34b23fed29841d63a3b77fda154eca876)
- ApexDox [`2662ae8`](https://github.com/dschach/ActionPlansV4/commit/2662ae868db1d30dd87eec48e81cf8a9568cff65)
- Create first package version [`53b252f`](https://github.com/dschach/ActionPlansV4/commit/53b252febede7e20351f82346a2b0dfc68b4b7f6)
- Org metadata and ignore files [`0725de0`](https://github.com/dschach/ActionPlansV4/commit/0725de02a377057af7f4fb9f6901d6d8384176ba)
- Removed TradeStyle to allow installation in regular orgs [`fa17e9d`](https://github.com/dschach/ActionPlansV4/commit/fa17e9d97d6ef1349475d8b7cde49606011b62fb)
- Handle ID lists [`b07c6a7`](https://github.com/dschach/ActionPlansV4/commit/b07c6a72c5c8162d55510d4c50da52bd3e983855)
- Works in managed package with unmanaged objects [`ef595b4`](https://github.com/dschach/ActionPlansV4/commit/ef595b4c57f44ee08b2d94bcf27738ed485fd1f8)
- Simplify installation instructions [`bdb2de3`](https://github.com/dschach/ActionPlansV4/commit/bdb2de3a738f00eab23287965e354bdc2bbf41f6)
- Readme update, ignore record types [`1412184`](https://github.com/dschach/ActionPlansV4/commit/1412184ae57ace230eb73cb9652e9ecbdcd5c184)
- Fix fieldset test visibility bug [`644087e`](https://github.com/dschach/ActionPlansV4/commit/644087e795cae2214dd2a775259537e07c4fc811)
- Class and method accessibility [`7515c2a`](https://github.com/dschach/ActionPlansV4/commit/7515c2ac2c60047b2f6cda655b73c50afc4727e9)
- Remove debugs [`07e4ee7`](https://github.com/dschach/ActionPlansV4/commit/07e4ee75d69ba6a9fb8dbb34e5aba3cdb3bad8b3)
- Release version 4.0.0-6 [`3f7a3fa`](https://github.com/dschach/ActionPlansV4/commit/3f7a3fa615c1623aad90cc105284243904d6139d)
- Script for working with custom object invocable [`9fe7c54`](https://github.com/dschach/ActionPlansV4/commit/9fe7c54ae80fa57baf48603bafbeaf227861c6e2)
- Create custom setting on install [`c3f795c`](https://github.com/dschach/ActionPlansV4/commit/c3f795c8b833df25877746ba17579c1493f9c02f)
- New task layout [`c31ec9f`](https://github.com/dschach/ActionPlansV4/commit/c31ec9f4f91c89e21cdb476c4053c6f0140f963a)
- Unprotect custom metadata so users can edit [`f947d4b`](https://github.com/dschach/ActionPlansV4/commit/f947d4b2c6632a19ea680352799a75eac8bc6176)
- Beta 3 [`19ace7e`](https://github.com/dschach/ActionPlansV4/commit/19ace7e5d04c68e62bfb37125e5941ad119f6330)
- ApexDox [`0076c54`](https://github.com/dschach/ActionPlansV4/commit/0076c543bc60834541223e0da28c749ab6a33367)
