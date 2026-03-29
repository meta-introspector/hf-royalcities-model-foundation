{ lib, buildPythonPackage, setuptools, wandb, src }:
buildPythonPackage {
  pname = "prefigure"; version = "0.0.10"; pyproject = true;
  inherit src; build-system = [ setuptools ]; dependencies = [ wandb ]; doCheck = false;
}
