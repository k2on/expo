import NativeErrorManager from './NativeErrorManager';
import EventEmitter from '../EventEmitter';
import Platform from '../Platform';
import { CodedError } from '../errors/CodedError';
if (__DEV__ && Platform.OS === 'android' && NativeErrorManager) {
    const onNewException = 'ExpoModulesCoreErrorManager.onNewException';
    const onNewWarning = 'ExpoModulesCoreErrorManager.onNewWarning';
    const eventEmitter = new EventEmitter(NativeErrorManager);
    eventEmitter.addListener(onNewException, (exception) => {
        console.error(exception.message);
    });
    eventEmitter.addListener(onNewWarning, (warning) => {
        console.warn(warning.message);
    });
}
// We have to export `CodedError` via global object to use in later in the C++ code.
globalThis.ExpoModulesCore_CodedError = CodedError;
//# sourceMappingURL=setUpErrorManager.fx.js.map