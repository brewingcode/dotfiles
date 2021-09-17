import importlib, pkgutil

def submodules(name, depth=0, curr=0, ignore_errors=False):
    '''recursively import everything individually under name, and return them as a flat list'''
    # depth: how deep to recurse (0 is unlimited)
    # curr: (internal use only)
    # ignore_errors: ignore import exceptions (only modules that successfully import are returned)
    #print(f'submodules: {name}, {depth}, {curr}, {ignore_errors}')

    if depth > 0 and curr > depth: return []

    try:
        modules = [ importlib.import_module(name) ]
        if hasattr(modules[0], '__path__'):
            for importer, modname, ispkg in pkgutil.iter_modules(modules[0].__path__):
                modules.extend(submodules(f'{name}.{modname}', depth, curr+1, ignore_errors))
        return modules
    except:
        if not ignore_errors: raise
        return []
