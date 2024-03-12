pip install cython
pip install numpy
python setup.py build_ext --inplace -j 0
mv pandas/conftest.py ./
