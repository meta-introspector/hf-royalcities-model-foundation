{ lib, buildPythonPackage, setuptools, torch, torchaudio, transformers
, numpy, soundfile, librosa, ftfy, webdataset, wandb, scipy, scikit-learn
, pandas, h5py, tqdm, regex, src }:
buildPythonPackage {
  pname = "laion-clap"; version = "1.1.6"; pyproject = true;
  inherit src; build-system = [ setuptools ];
  dependencies = [ torch torchaudio transformers numpy soundfile librosa ftfy webdataset wandb scipy scikit-learn pandas h5py tqdm regex ];
  doCheck = false;
}
