# NBCoreBluetoothAPIMisuseGuard
A drop in category which prevents CoreBluetooth methods being called when the state is not 'powered on'

## Usage

Just drag into your project which uses CoreBluetooth and add a breakpoint for All Exceptions.

The code will only be compiled in debug builds.

## License

MIT
