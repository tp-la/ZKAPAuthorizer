{ lib
, buildPythonPackage, sphinx, git
, attrs, zope_interface, aniso8601, twisted, tahoe-lafs, privacypass, treq
, fixtures, testtools, hypothesis, pyflakes, coverage
, hypothesisProfile ? null
, collectCoverage ? false
, testSuite ? null
, trialArgs ? null
}:
let
  hypothesisProfile' = if hypothesisProfile == null then "default" else hypothesisProfile;
  testSuite' = if testSuite == null then "_zkapauthorizer" else testSuite;
  defaultTrialArgs = [ "--rterrors" ] ++ ( lib.optional ( ! collectCoverage ) "--jobs=$NIX_BUILD_CORES" );
  trialArgs' = if trialArgs == null then defaultTrialArgs else trialArgs;
  extraTrialArgs = builtins.concatStringsSep " " trialArgs';
in
buildPythonPackage rec {
  version = "0.0";
  pname = "zero-knowledge-access-pass-authorizer";
  name = "${pname}-${version}";
  src = ./.;

  outputs = [ "out" ] ++ (if collectCoverage then [ "doc" ] else [ ]);

  depsBuildBuild = [
    git
    sphinx
  ];

  propagatedBuildInputs = [
    attrs
    zope_interface
    aniso8601
    twisted
    tahoe-lafs
    privacypass
    treq
  ];

  checkInputs = [
    coverage
    fixtures
    testtools
    hypothesis
  ];

  checkPhase = ''
    runHook preCheck
    "${pyflakes}/bin/pyflakes" src/_zkapauthorizer
    ZKAPAUTHORIZER_HYPOTHESIS_PROFILE=${hypothesisProfile'} python -m ${if collectCoverage
      then "coverage run --branch --source _zkapauthorizer,twisted.plugins.zkapauthorizer --module"
      else ""
    } twisted.trial ${extraTrialArgs} ${testSuite'}
    runHook postCheck
  '';

  postCheck = if collectCoverage
    then ''
    python -m coverage html
    mkdir -p "$doc/share/doc/${name}"
    cp -vr .coverage htmlcov "$doc/share/doc/${name}"
    python -m coverage report
    ''
    else "";
}
