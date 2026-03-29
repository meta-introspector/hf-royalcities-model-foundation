{ lib, buildPythonPackage, setuptools, torch, numpy, src }:
buildPythonPackage {
  pname = "auraloss"; version = "0.4.0";
  format = "setuptools";
  inherit src; build-system = [ setuptools ]; dependencies = [ torch numpy ]; doCheck = false;
}
