//
//  BleMidiParser.m
//  Pods
//
//  Created by tanhui on 2017/8/23.
//
//

#import "BleMidiParser.h"
#import "musicXML.h"
#import "Constants.h"
const int kMaxBufferSize=256; // max lenght for sysex buffer size

//Receiver *midiRecv;

static int MIDI_STATE_TIMESTAMP = 0;
static int MIDI_STATE_WAIT = 1;
static int MIDI_STATE_SIGNAL_2BYTES_2 = 21;
static int MIDI_STATE_SIGNAL_3BYTES_2 = 31;
static int MIDI_STATE_SIGNAL_3BYTES_3 = 32;
static int MIDI_STATE_SIGNAL_SYSEX = 41;

// for Timestamp
static int MAX_TIMESTAMP = 8192;
static int BUFFER_LENGTH_MILLIS = 10;


// for RPN/NRPN messages
static int PARAMETER_MODE_NONE = 0;
static int PARAMETER_MODE_RPN = 1;
static int PARAMETER_MODE_NRPN = 2;
static int parameterMode = 0;
static int parameterNumber = 0x3fff;
static int parameterValue = 0x3fff;

@interface BleMidiParser (){
    uint8_t midiBuffer[3];
    uint8_t sysExBuffer[kMaxBufferSize];
    uint8_t alterSysExBuffer[kMaxBufferSize];
    
    int midiBufferPtr ;   // int midiBufferPtr = 0;
    int sysExRecBufferPtr ;  // int sysExRecBufferPtr = 0;
    int sysExBufferPtr ;     // int sysExBufferPtr = 0;
    
    // MIDI event messages, state & stamps
    int midiEventKind;
    int midiEventNote;
    int midiEventVelocity;
    int midiState;   //int midiState = MIDI_STATE_TIMESTAMP;
    int timestamp;
    
    bool useTimestamp ; // bool useTimestamp = true;
    
    int lastTimestamp;
    long lastTimestampRecorded ;  //  long lastTimestampRecorded = 0;
    int zeroTimestampCount;     //   int zeroTimestampCount = 0;
}

@end

@implementation BleMidiParser


-(void)addByteToMidiBuffer:(uint8_t) midiEvent {
    midiBuffer[midiBufferPtr] = midiEvent;
    midiBufferPtr++;
}

-(void)addByteToSysExBuffer:(uint8_t) midiEvent {
    sysExBuffer[sysExBufferPtr] = midiEvent;
    sysExBufferPtr++;
}

-(uint8_t) replaceLastByteInSysExBuffer:(uint8_t) midiEvent {
    sysExBufferPtr--;
    uint8_t lastEvt = sysExBuffer[sysExBufferPtr];
    sysExBuffer[sysExBufferPtr] = midiEvent;
    sysExBufferPtr++;
    return lastEvt;
}

-(void) sendSysex {
    
    for(int i = 0 ; i<=sysExBufferPtr; i++ ) { // send sysex message on the UART
        //      Serial.write(sysExBuffer[i]) ;
    }
}

-(void) createSysExRecovery {
    sysExRecBufferPtr = sysExBufferPtr;
    memcpy(alterSysExBuffer, sysExBuffer, sysExBufferPtr);
}

-(void) sendSysexRecovery {
    
    for(int i = 0 ; i<=sysExRecBufferPtr; i++ ) {
        //      Serial.write(alterSysExBuffer[i]) ;
    }
}

-(uint8_t) replaceLastByteInRecoveryBuffer:(uint8_t) midiEvent {
    sysExRecBufferPtr--;
    uint8_t lastEvt = alterSysExBuffer[sysExRecBufferPtr];
    alterSysExBuffer[sysExRecBufferPtr] = midiEvent;
    sysExRecBufferPtr++;
    return lastEvt;
}

-(void) addByteToRecoveryBuffer:(uint8_t) midiEvent{
    alterSysExBuffer[sysExRecBufferPtr] = midiEvent;
    sysExRecBufferPtr++;
}

-(void) resetMidiBuffer {
    memset(&midiBuffer[0], 0, sizeof(midiBuffer));
    midiBufferPtr = 0;
}

-(void) resetSysExBuffer {
    memset(&sysExBuffer[0], 0, kMaxBufferSize);
    sysExBufferPtr = 0;
}

-(void) resetRecoveryBuffer {
    memset(&alterSysExBuffer[0], 0, sizeof(alterSysExBuffer));
    sysExRecBufferPtr = 0;
}

-(void) sendMidi:(uint8_t) size { // send MIDI Message on the UART
//    for(int i = 0 ; i<=size ; i++ ) {
//        printf("%d ",midiBuffer[i]);
//    }
//    printf("\n");
}

-(void)parse:(char* )data length:(int)length atMS:(double)ms{
    if (length>1) {
        int header = data[0] & 0xff;
        for (int i = 1; i < length; i++) {
            [self parseMidiHeader:header event:(const uint8_t)data[i] atMS:ms] ;
        }
    }
}

-(void) parseMidiHeader:(uint8_t) header event:(const uint8_t) event atMS:(double)ms{
    uint8_t midiEvent = event & 0xff;
    
    // printf((char*)midiEvent);
    if (midiState == MIDI_STATE_TIMESTAMP)
    {
        // printf("Timestamp");
        if ((midiEvent & 0x80) == 0)
        {
            // running status
            midiState = MIDI_STATE_WAIT;
        }
        
        if (midiEvent == 0xf7)
        {
            // make sure this is the end of sysex
            // and send alternative recovery stream
            if (sysExRecBufferPtr > 0)
            {
                uint8_t removed = [self replaceLastByteInRecoveryBuffer:midiEvent];
                [self sendSysexRecovery];
                [self resetRecoveryBuffer];
            }
            midiState = MIDI_STATE_TIMESTAMP;
            return;
        }
        else
        {
            // reset alternative sysex stream
            [self resetRecoveryBuffer];
        }
    } // end of timestamp
    
    if (midiState == MIDI_STATE_TIMESTAMP)
    {
        timestamp = ((header & 0x3f) << 7) | (midiEvent & 0x7f);
        midiState = MIDI_STATE_WAIT;
    }
    else if (midiState == MIDI_STATE_WAIT)
    {
        switch (midiEvent & 0xf0) {
            case 0xf0: {
                switch (midiEvent) {
                    case 0xf0:
                        [self resetRecoveryBuffer];
                        [self resetSysExBuffer];
                        [self addByteToSysExBuffer:midiEvent];
                        midiState = MIDI_STATE_SIGNAL_SYSEX;
                        break;
                    case 0xf1:
                    case 0xf3:
                        // 0xf1 MIDI Time Code Quarter Frame. : 2bytes
                        // 0xf3 Song Select. : 2bytes
                        midiEventKind = midiEvent;
                        [self addByteToMidiBuffer:midiEvent];
                        midiState = MIDI_STATE_SIGNAL_2BYTES_2;
                        break;
                    case 0xf2:
                        // 0xf2 Song Position Pointer. : 3bytes
                        midiEventKind = midiEvent;
                        [self addByteToMidiBuffer:midiEvent];
                        midiState = MIDI_STATE_SIGNAL_3BYTES_2;
                        break;
                    case 0xf6:
                        // 0xf6 Tune Request : 1byte
                        [self addByteToMidiBuffer:midiEvent];
                        midiState = MIDI_STATE_TIMESTAMP;
                        break;
                    case 0xf8:
                        // 0xf8 Timing Clock : 1byte
                        //#pragma mark send timeclock // no on mbed OS
                        midiState = MIDI_STATE_TIMESTAMP;
                        break;
                    case 0xfa:
                        // 0xfa Start : 1byte
                        midiState = MIDI_STATE_TIMESTAMP;
                        break;
                    case 0xfb:
                        // 0xfb Continue : 1byte
                        midiState = MIDI_STATE_TIMESTAMP;
                        break;
                    case 0xfc:
                        // 0xfc Stop : 1byte
                        midiState = MIDI_STATE_TIMESTAMP;
                        break;
                    case 0xfe:
                        // 0xfe Active Sensing : 1byte
                        midiState = MIDI_STATE_TIMESTAMP;
                        break;
                    case 0xff:
                        // 0xff Reset : 1byte
                        midiState = MIDI_STATE_TIMESTAMP;
                        break;
                        
                    default:
                        break;
                }
            }
                break;
            case 0x80:
            case 0x90:
            case 0xa0:
            case 0xb0:
            case 0xe0:
                // 3bytes pattern
                midiEventKind = midiEvent;
                midiState = MIDI_STATE_SIGNAL_3BYTES_2;
                break;
            case 0xc0: // program change
            case 0xd0: // channel after-touch
                // 2bytes pattern
                midiEventKind = midiEvent;
                midiState = MIDI_STATE_SIGNAL_2BYTES_2;
                break;
            default:
                // 0x00 - 0x70: running status
                if ((midiEventKind & 0xf0) != 0xf0) {
                    // previous event kind is multi-bytes pattern
                    midiEventNote = midiEvent;
                    midiState = MIDI_STATE_SIGNAL_3BYTES_3;
                }
                break;
        }
    }
    else if (midiState == MIDI_STATE_SIGNAL_2BYTES_2)
    {
        switch (midiEventKind & 0xf0)
        {
                // 2bytes pattern
            case 0xc0: // program change
                midiEventNote = midiEvent;
                midiState = MIDI_STATE_TIMESTAMP;
                break;
            case 0xd0: // channel after-touch
                midiEventNote = midiEvent;
                midiState = MIDI_STATE_TIMESTAMP;
                break;
            case 0xf0:
            {
                switch (midiEventKind)
                {
                    case 0xf1:
                        // 0xf1 MIDI Time Code Quarter Frame. : 2bytes
                        midiEventNote = midiEvent;
                        [self addByteToMidiBuffer:midiEventNote];
                        [self sendMidi:2];
                        [self resetMidiBuffer];
                        midiState = MIDI_STATE_TIMESTAMP;
                        break;
                    case 0xf3:
                        // 0xf3 Song Select. : 2bytes
                        midiEventNote = midiEvent;
                        [self addByteToMidiBuffer:midiEventNote];
                        [self sendMidi:2];
                        [self resetMidiBuffer];
                        midiState = MIDI_STATE_TIMESTAMP;
                        break;
                    default:
                        // illegal state
                        midiState = MIDI_STATE_TIMESTAMP;
                        break;
                }
            }
                break;
            default:
                // illegal state
                midiState = MIDI_STATE_TIMESTAMP;
                break;
        }
    }
    else if (midiState == MIDI_STATE_SIGNAL_3BYTES_2)
    {
        switch (midiEventKind & 0xf0)
        {
            case 0x80:
            case 0x90:
            case 0xa0:
            case 0xb0:
            case 0xe0:
            case 0xf0:
                // 3bytes pattern
                midiEventNote = midiEvent;
                midiState = MIDI_STATE_SIGNAL_3BYTES_3;
                break;
            default:
                // illegal state
                midiState = MIDI_STATE_TIMESTAMP;
                break;
        }
    }
    else if (midiState == MIDI_STATE_SIGNAL_3BYTES_3)
    {
        switch (midiEventKind & 0xf0)
        {
                // 3bytes pattern
            case 0x80: // note off
                
                midiEventVelocity = midiEvent;
                
                [self onMidiNoteOffWithKind:midiEventKind&0xf note:midiEventNote velocity:midiEventVelocity ms:ms];
                
                [self addByteToMidiBuffer:midiEventKind];
                [self addByteToMidiBuffer:midiEventNote];
                [self addByteToMidiBuffer:midiEventVelocity];
                [self sendMidi:3];
                [self resetMidiBuffer];
                midiState = MIDI_STATE_TIMESTAMP;
                break;
            case 0x90: // note on
                midiEventVelocity = midiEvent;
                //timeToWait = calculateTimeToWait(timestamp);
                
                if (midiEventVelocity == 0) {
                    [self onMidiNoteOffWithKind:midiEventKind&0xf note:midiEventNote velocity:midiEventVelocity ms:ms];
                }else {
                    [self onMidiNoteOnWithKind:midiEventKind&0xf note:midiEventNote velocity:midiEventVelocity ms:ms];
                }
                
                [self addByteToMidiBuffer:midiEventKind];
                [self addByteToMidiBuffer:midiEventNote];
                [self addByteToMidiBuffer:midiEventVelocity];
                [self sendMidi:3];
                [self resetMidiBuffer];
                midiState = MIDI_STATE_TIMESTAMP;
                break;
            case 0xa0: // control polyphonic key pressure
                midiEventVelocity = midiEvent;
                [self addByteToMidiBuffer:midiEventKind];
                [self addByteToMidiBuffer:midiEventNote];
                [self addByteToMidiBuffer:midiEventVelocity];
                [self sendMidi:3];
                [self resetMidiBuffer];
                midiState = MIDI_STATE_TIMESTAMP;
                break;
            case 0xb0: // control change
                midiEventVelocity = midiEvent;
                switch (midiEventNote & 0x7f)
            {
                case 98:
                    // NRPN LSB
                    parameterNumber &= 0x3f80;
                    parameterNumber |= midiEventVelocity & 0x7f;
                    parameterMode = PARAMETER_MODE_NRPN;
                    break;
                case 99:
                    // NRPN MSB
                    parameterNumber &= 0x007f;
                    parameterNumber |= (midiEventVelocity & 0x7f) << 7;
                    parameterMode = PARAMETER_MODE_NRPN;
                    break;
                case 100:
                    // RPN LSB
                    parameterNumber &= 0x3f80;
                    parameterNumber |= midiEventVelocity & 0x7f;
                    parameterMode = PARAMETER_MODE_RPN;
                    break;
                case 101:
                    // RPN MSB
                    parameterNumber &= 0x007f;
                    parameterNumber |= (midiEventVelocity & 0x7f) << 7;
                    parameterMode = PARAMETER_MODE_RPN;
                    break;
                case 38:
                    // data LSB
                    parameterValue &= 0x3f80;
                    parameterValue |= midiEventVelocity & 0x7f;
                    
                    if (parameterNumber != 0x3fff) {
                        if (parameterMode == PARAMETER_MODE_RPN)
                        {
                            [self addByteToMidiBuffer:midiEventKind];
                            [self addByteToMidiBuffer:parameterNumber];
                            [self addByteToMidiBuffer:parameterValue];
                            [self sendMidi:3];
                            [self resetMidiBuffer];
                        }
                        else if (parameterMode == PARAMETER_MODE_NRPN)
                        {
                            [self addByteToMidiBuffer:midiEventKind];
                            [self addByteToMidiBuffer:parameterNumber];
                            [self addByteToMidiBuffer:parameterValue];
                            [self sendMidi:3];
                            [self resetMidiBuffer];
                        }
                    }
                    break;
                case 6:
                    // data MSB
                    parameterValue &= 0x007f;
                    parameterValue |= (midiEventVelocity & 0x7f) << 7;
                    
                    if (parameterNumber != 0x3fff)
                    {
                        if (parameterMode == PARAMETER_MODE_RPN)
                        {
                            [self addByteToMidiBuffer:midiEventKind];
                            [self addByteToMidiBuffer:parameterNumber];
                            [self addByteToMidiBuffer:parameterValue];
                            [self sendMidi:3];
                            [self resetMidiBuffer];
                        }
                        else if (parameterMode == PARAMETER_MODE_NRPN)
                        {
                            [self addByteToMidiBuffer:midiEventKind];
                            [self addByteToMidiBuffer:parameterNumber];
                            [self addByteToMidiBuffer:parameterValue];
                            [self sendMidi:3];
                            [self resetMidiBuffer];
                        }
                    }
                    break;
                default:
                    // do nothing
                    break;
            }
                [self addByteToMidiBuffer:midiEventKind];
                [self addByteToMidiBuffer:midiEventNote];
                [self addByteToMidiBuffer:midiEventVelocity];
                [self sendMidi:3];
                [self resetMidiBuffer];
                midiState = MIDI_STATE_TIMESTAMP;
                break;
            case 0xe0: // pitch bend
                midiEventVelocity = midiEvent;
                [self addByteToMidiBuffer:midiEventKind];
                [self addByteToMidiBuffer:midiEventNote];
                [self addByteToMidiBuffer:midiEventVelocity];
                [self sendMidi:3];
                [self resetMidiBuffer];
                midiState = MIDI_STATE_TIMESTAMP;
                break;
            case 0xf0: // Song Position Pointer.
                midiEventVelocity = midiEvent;
                [self addByteToMidiBuffer:midiEventKind];
                [self addByteToMidiBuffer:midiEventNote];
                [self addByteToMidiBuffer:midiEventVelocity];
                [self sendMidi:3];
                [self resetMidiBuffer];
                midiState = MIDI_STATE_TIMESTAMP;
                break;
            default:
                // illegal state
                midiState = MIDI_STATE_TIMESTAMP;
                break;
        }
    }
    else if (midiState == MIDI_STATE_SIGNAL_SYSEX)
    {
        if (midiEvent == 0xf7)
        {
            uint8_t repEvt = [self replaceLastByteInSysExBuffer:midiEvent];
            
            [self resetRecoveryBuffer];
            [self createSysExRecovery];
            [self replaceLastByteInRecoveryBuffer:repEvt];
            [self addByteToRecoveryBuffer:midiEvent];
            [self sendSysex];
            [self resetSysExBuffer];
            midiState = MIDI_STATE_TIMESTAMP;
        }
        else
        {
            [self addByteToSysExBuffer:midiEvent];
        }
        
    }
}


-(void)onMidiNoteOffWithKind:(int)midiEventChannel note:(int)midiEventNote velocity:(int)midiEventVelocity ms:(double)ms{
    if (midiEventChannel == 0 || midiEventChannel == 1 || midiEventChannel == 2) {
        
        [[NSNotificationCenter defaultCenter]postNotificationName:ScoreDidReceiveMidiOffNotification object:@{
                                                                                                             @"channel":@(midiEventChannel),
                                                                                                             @"note":@(midiEventNote),
                                                                                                             @"velocity":@(midiEventVelocity),
                                                                                                             @"ms":@(ms),
                                                                                                             }];
    }
}

-(void)onMidiNoteOnWithKind:(int)midiEventChannel note:(int)midiEventNote velocity:(int)midiEventVelocity ms:(double)ms{
//    CILog(@"channel ---- %d",midiEventChannel);m
    if (midiEventChannel == 0 || midiEventChannel == 1 || midiEventChannel == 2) {
        
        [[NSNotificationCenter defaultCenter]postNotificationName:ScoreDidReceiveMidiOnNotification object:@{
                                                                                                              @"channel":@(midiEventChannel),
                                                                                                              @"note":@(midiEventNote),
                                                                                                              @"velocity":@(midiEventVelocity),
                                                                                                              @"ms":@(ms),
                                                                                                              }];
    }
}


@end
