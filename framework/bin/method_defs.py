import argparse
import sys
from typing import List
import ast


class Container:
    def __init__(self, name, start, end):
        self.name = name
        self.start = start
        self.end = end
        self.children: List[Container] = []

    def add_child(self, cont):
        self.children.append(cont)

    def is_in(self, line):
        return self.start <= line <= self.end

    def get_def_list(self, line):
        def_list = []
        for child in self.children:
            if (child.is_in(line)):
                def_list = child.get_def_list(line)
        if (self.name != '<module>' or len(def_list) == 0):
            def_list.insert(0, self.name)
        return def_list

    def __str__(self):
        if (self.children):
            children = ' ['+', '.join([str(c) for c in self.children])+']'
        else:
            children = ""
        return f'{self.name} ({self.start}, {self.end}){children}'


def get_defs(filename: str):
    """Retrieves the line numbers for each function and class"""
    parsed_ast = ast.parse(open(filename, 'r').read())
    if (len(parsed_ast.body) > 0):
        module = Container('<module>', parsed_ast.body[0].lineno,
                           parsed_ast.body[-1].end_lineno)
    else:
        module = Container('<module>', 1, 1)

    def fill_nodes(curr_def: Container, ast_node: ast.AST):
        for node in ast.iter_child_nodes(ast_node):
            if (isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef,
                                  ast.ClassDef))):
                child = Container(node.name, node.lineno, node.end_lineno)
                curr_def.add_child(child)
                fill_nodes(child, node)

    fill_nodes(module, parsed_ast)
    return module


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("file", action='store', type=argparse.FileType('r'),
                        help='The name of the python file to parse')
    args = parser.parse_args()
    module = get_defs(args.file)
    for line in sys.stdin:
        print(*module.get_def_list(int(line.strip())), sep=".")
