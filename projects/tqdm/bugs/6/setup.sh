python setup.py install
eval echo -e "[pytest]\\ntestpaths= tqdm/tests\\npython_files = tests_*.py" > pytest.ini
pip3 install nose
pip3 install flake8
pip3 install coverage
pip3 install pytest
