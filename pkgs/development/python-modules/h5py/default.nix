{ lib
, fetchPypi
, buildPythonPackage
, pythonOlder
, setuptools
, numpy
, hdf5
, cython
, pkgconfig
, mpi4py ? null
, openssh
, pytestCheckHook
, cached-property
}:

assert hdf5.mpiSupport -> mpi4py != null && hdf5.mpi == mpi4py.mpi;

let
  mpi = hdf5.mpi;
  mpiSupport = hdf5.mpiSupport;
in buildPythonPackage rec {
  version = "3.7.0";
  pname = "h5py";
  format = "pyproject";

  disabled = pythonOlder "3.7";

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-P883iEODxdpkhGq1EBkHIAJ9ygdo3vNN2Ny2Wdvly/M=";
  };

  # avoid strict pinning of numpy
  postPatch = ''
    substituteInPlace setup.py \
      --replace "numpy ==" "numpy >=" \
      --replace "mpi4py ==" "mpi4py >="
  '';

  HDF5_DIR = "${hdf5}";
  HDF5_MPI = if mpiSupport then "ON" else "OFF";

  postConfigure = ''
    # Needed to run the tests reliably. See:
    # https://bitbucket.org/mpi4py/mpi4py/issues/87/multiple-test-errors-with-openmpi-30
    ${lib.optionalString mpiSupport "export OMPI_MCA_rmaps_base_oversubscribe=yes"}
  '';

  preBuild = lib.optionalString mpiSupport "export CC=${mpi}/bin/mpicc";

  nativeBuildInputs = [
    cython
    pkgconfig
    setuptools
  ];

  buildInputs = [ hdf5 ]
    ++ lib.optional mpiSupport mpi;

  propagatedBuildInputs = [ numpy ]
    ++ lib.optionals mpiSupport [ mpi4py openssh ]
    ++ lib.optionals (pythonOlder "3.8") [ cached-property ];

  # tests now require pytest-mpi, which isn't available and difficult to package
  doCheck = false;
  nativeCheckInputs = [ pytestCheckHook openssh ];

  pythonImportsCheck = [ "h5py" ];

  meta = with lib; {
    description = "Pythonic interface to the HDF5 binary data format";
    homepage = "http://www.h5py.org/";
    license = licenses.bsd3;
    maintainers = [ ];
  };
}
