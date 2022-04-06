from functools import wraps


def flame(cls):
    singleton = cls()

    for attr_name in dir(singleton):
        method = getattr(singleton, attr_name)
        if (
            not callable(method) or
            attr_name.startswith("__") and
            attr_name.endswith("__")
        ):
            continue

        def clojure(method_):
            @wraps(method_)
            def wrapper(*args, **kwargs):
                for parameter_name, annotation in method_.__annotations__.items():
                    kwargs[parameter_name] = annotation(
                        kwargs.get(
                            parameter_name,
                            method_.__kwdefaults__[parameter_name]
                        )
                    )

                return method_(*args, **kwargs)
            return wrapper

        setattr(singleton, attr_name, clojure(method))

    return singleton
