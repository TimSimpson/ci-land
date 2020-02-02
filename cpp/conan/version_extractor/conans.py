# Prints out the "name" and "version" of the conan class.

class PrintDetails(type):
    def __init__(cls, name, bases, clsdict):
        if len(cls.mro()) > 2:
            print(f"{cls.name}/{cls.version}")

        super(PrintDetails, cls).__init__(name, bases, clsdict)


class ConanFile(metaclass=PrintDetails):
    pass
